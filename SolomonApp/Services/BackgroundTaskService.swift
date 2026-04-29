import Foundation
import os
import BackgroundTasks
import UserNotifications
import SolomonCore
import SolomonStorage
import SolomonMoments
import SolomonAnalytics

// MARK: - BackgroundTaskService
//
// Gestionează BGTaskScheduler pentru momentele Solomon auto-declanșate:
//
//   ro.solomon.app.moment.refresh  — BGAppRefreshTask, la fiecare 3+ ore.
//     Detectează: salariu primit (Payday), obligație iminentă, Pattern/Spiral.
//     Trimite push dacă permisiunile sunt acordate.
//
//   ro.solomon.app.moment.weekly   — BGProcessingTask, duminică seara ~20:00.
//     Generează rezumatul săptămânal și trimite push.
//
// Wiring în SolomonApp:
//   1. init() → BackgroundTaskService.shared.registerHandlers()
//   2. .onChange(of: scenePhase) { if phase == .background { scheduleAll() } }

@MainActor
final class BackgroundTaskService {

    static let shared = BackgroundTaskService()

    nonisolated static let taskIdRefresh = "ro.solomon.app.moment.refresh"
    nonisolated static let taskIdWeekly  = "ro.solomon.app.moment.weekly"

    private let persistence = SolomonPersistenceController.shared

    private init() {}

    // MARK: - Register (apelat din App.init() — înainte de prima scenă)

    nonisolated func registerHandlers() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdRefresh,
            using: nil
        ) { task in
            // BGTask nu e Sendable în Swift 6 — nonisolated(unsafe) e escape hatch aprobat.
            // Folosim as? + guard în loc de force-cast pentru crash safety.
            nonisolated(unsafe) let rawTask = task
            Task { @MainActor in
                guard let t = rawTask as? BGAppRefreshTask else {
                    rawTask.setTaskCompleted(success: false)
                    return
                }
                await BackgroundTaskService.shared.handleRefresh(task: t)
            }
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdWeekly,
            using: nil
        ) { task in
            nonisolated(unsafe) let rawTask = task
            Task { @MainActor in
                guard let t = rawTask as? BGProcessingTask else {
                    rawTask.setTaskCompleted(success: false)
                    return
                }
                await BackgroundTaskService.shared.handleWeekly(task: t)
            }
        }
    }

    // MARK: - Schedule (apelat când app intră în background)

    func scheduleAll() {
        scheduleRefresh()
        scheduleWeekly()
    }

    private func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdRefresh)
        // Minimum 3 ore — iOS poate întârzia mai mult
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3 * 60 * 60)
        // FAZA C6: log explicit BGTaskScheduler errors. Eșecul aici e normal pe simulator
        // (BGTaskSchedulerErrorDomain code 1) sau dacă userul a dezactivat BG App Refresh.
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.bgTask.debug("BG refresh task scheduled for \(request.earliestBeginDate?.description ?? "now", privacy: .public)")
        } catch {
            Logger.bgTask.warning("BG refresh submit failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func scheduleWeekly() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdWeekly)
        request.earliestBeginDate = nextSundayEvening()
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.bgTask.debug("BG weekly task scheduled for \(request.earliestBeginDate?.description ?? "next Sunday", privacy: .public)")
        } catch {
            Logger.bgTask.warning("BG weekly submit failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func nextSundayEvening() -> Date {
        let cal = Calendar.current
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // 1=Sun, 7=Sat
        let daysUntilSunday = weekday == 1 ? 7 : 8 - weekday
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.day = (comps.day ?? 0) + daysUntilSunday
        comps.hour = 20
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps) ?? Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)
    }

    // MARK: - Handle: Daily Refresh (Payday, Upcoming Obligation, Pattern, Spiral)

    private func handleRefresh(task: BGAppRefreshTask) async {
        // Re-schedule pentru rulare viitoare
        scheduleRefresh()

        let snapshot = buildSnapshot()
        let engine = MomentEngine(llm: ModelDownloadService.shared.makeLLMProvider())
        let selected = engine.selectedType(snapshot: snapshot)

        // Trimite push doar pentru momente acționabile (nu Wow/generic)
        if let type = selected, shouldPush(type) {
            await sendPushNotification(for: type)
        }

        task.setTaskCompleted(success: true)
    }

    // MARK: - Handle: Weekly Summary

    private func handleWeekly(task: BGProcessingTask) async {
        scheduleWeekly()

        let snapshot = buildSnapshot()
        let engine = MomentEngine(llm: ModelDownloadService.shared.makeLLMProvider())
        let selected = engine.selectedType(snapshot: snapshot)

        if selected == .weeklySummary {
            await sendPushNotification(for: .weeklySummary)
        }

        task.setTaskCompleted(success: true)
    }

    // MARK: - Snapshot builder

    private func buildSnapshot() -> MomentEngine.Snapshot {
        let ctx = persistence.container.viewContext
        let txRepo   = CoreDataTransactionRepository(context: ctx)
        let oblRepo  = CoreDataObligationRepository(context: ctx)
        let subRepo  = CoreDataSubscriptionRepository(context: ctx)
        let goalRepo = CoreDataGoalRepository(context: ctx)
        let profileRepo = CoreDataUserProfileRepository(context: ctx)

        return MomentEngine.Snapshot(
            userProfile: try? profileRepo.fetchProfile(),
            transactions: (try? txRepo.fetchAll()) ?? [],
            obligations: (try? oblRepo.fetchAll()) ?? [],
            subscriptions: (try? subRepo.fetchAll()) ?? [],
            goals: (try? goalRepo.fetchAll()) ?? []
        )
    }

    // MARK: - Push helpers

    private func shouldPush(_ type: MomentType) -> Bool {
        switch type {
        case .payday, .upcomingObligation, .patternAlert, .weeklySummary, .spiralAlert, .subscriptionAudit:
            return true
        case .canIAfford, .wowMoment:
            return false
        }
    }

    /// Trimite notificare push dacă userul a acordat permisiunea.
    func sendPushNotification(for type: MomentType) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.badge = 1

        switch type {
        case .payday:
            content.title = "Salariul a intrat 💚"
            content.body = "Solomon a pregătit alocarea automată. Deschide app-ul să vezi."
            content.interruptionLevel = .timeSensitive
        case .upcomingObligation:
            content.title = "Plată obligatorie se apropie ⏰"
            content.body = "Ai o obligație care scade în curând. Deschide Solomon să verifici."
            // FAZA B3: time-sensitive ca să străbată Focus mode
            content.interruptionLevel = .timeSensitive
        case .patternAlert:
            content.title = "Solomon a observat ceva"
            content.body = "Cheltuielile tale arată un pattern. Tap pentru detalii."
            content.interruptionLevel = .active
        case .weeklySummary:
            content.title = "Rezumatul tău săptămânal 📊"
            content.body = "Cum a mers săptămâna financiar? Deschide Solomon să afli."
            content.interruptionLevel = .passive
        case .spiralAlert:
            content.title = "Atenție — alertă financiară 🔴"
            content.body = "Solomon a detectat presiune financiară. Deschide app-ul acum."
            // FAZA B3: spirala financiară ESTE urgență — folosim .critical dacă
            // entitlement-ul e disponibil; iOS auto-degrade la .timeSensitive dacă nu.
            content.interruptionLevel = .critical
            content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        case .subscriptionAudit:
            content.title = "Abonamente nefolosite găsite 💸"
            content.body = "Poți recupera bani anulând abonamente fantomă. Tap să vezi."
            content.interruptionLevel = .active
        default:
            return
        }

        let id = "solomon.bg.\(type.rawValue).\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        do {
            try await center.add(request)
        } catch {
            // FAZA C6: log explicit în loc de try? silent
            Logger.bgTask.error("Push notification add failed for \(type.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
