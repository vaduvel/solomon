import Foundation
import SolomonCore

// MARK: - Candidates

/// Bag de contexte disponibile pentru selecție de orchestrator.
///
/// Nu toate momentele sunt disponibile simultan — orchestratorrul primește
/// doar contextele relevante pentru sesiunea curentă.
public struct MomentCandidates: Sendable {
    public var wowMoment: WowMomentContext?
    public var canIAfford: CanIAffordContext?
    public var payday: PaydayContext?
    public var upcomingObligation: UpcomingObligationContext?
    public var patternAlert: PatternAlertContext?
    public var subscriptionAudit: SubscriptionAuditContext?
    public var spiralAlert: SpiralAlertContext?
    public var weeklySummary: WeeklySummaryContext?

    public init(
        wowMoment: WowMomentContext? = nil,
        canIAfford: CanIAffordContext? = nil,
        payday: PaydayContext? = nil,
        upcomingObligation: UpcomingObligationContext? = nil,
        patternAlert: PatternAlertContext? = nil,
        subscriptionAudit: SubscriptionAuditContext? = nil,
        spiralAlert: SpiralAlertContext? = nil,
        weeklySummary: WeeklySummaryContext? = nil
    ) {
        self.wowMoment = wowMoment
        self.canIAfford = canIAfford
        self.payday = payday
        self.upcomingObligation = upcomingObligation
        self.patternAlert = patternAlert
        self.subscriptionAudit = subscriptionAudit
        self.spiralAlert = spiralAlert
        self.weeklySummary = weeklySummary
    }

    /// True dacă cel puțin un context este disponibil.
    public var hasAnyCandidate: Bool {
        wowMoment != nil || canIAfford != nil || payday != nil ||
        upcomingObligation != nil || patternAlert != nil ||
        subscriptionAudit != nil || spiralAlert != nil || weeklySummary != nil
    }
}

// MARK: - OrchestratorError

public enum OrchestratorError: Error, Sendable {
    /// Nu există niciun context disponibil pentru a genera un moment.
    case noCandidatesAvailable
    /// Momentul selectat nu a putut fi generat.
    case buildFailed(momentType: MomentType, underlying: Error)
}

// MARK: - Orchestrator

/// Selectează și generează cel mai relevant moment Solomon bazat pe prioritate.
///
/// Ordinea de prioritate (spec §5.1):
/// 1. SpiralAlert   — urgență; spiralScore >= 2
/// 2. CanIAfford    — reactiv; dacă utilizatorul a întrebat explicit
/// 3. UpcomingObligation — time-sensitive; daysUntilDue <= 3
/// 4. Payday        — declanșat de detecția salariului
/// 5. PatternAlert  — proactiv
/// 6. SubscriptionAudit — periodic
/// 7. WeeklySummary — scheduled
/// 8. WowMoment     — onboarding (fallback)
public struct MomentOrchestrator: Sendable {

    // MARK: - Builders (all initialized once)

    private let wowBuilder = WowMomentBuilder()
    private let canIAffordBuilder = CanIAffordBuilder()
    private let paydayBuilder = PaydayMagicBuilder()
    private let upcomingBuilder = UpcomingObligationBuilder()
    private let patternBuilder = PatternAlertBuilder()
    private let subscriptionBuilder = SubscriptionAuditBuilder()
    private let spiralBuilder = SpiralAlertBuilder()
    private let weeklyBuilder = WeeklySummaryBuilder()

    public init() {}

    // MARK: - Select

    /// Returnează tipul momentului care ar fi selectat fără a-l genera.
    /// Util pentru UI (preview ce urmează).
    public func selectedType(from candidates: MomentCandidates) -> MomentType? {
        if let spiral = candidates.spiralAlert, spiral.spiralScore >= 2 {
            return .spiralAlert
        }
        if candidates.canIAfford != nil { return .canIAfford }
        if let obligation = candidates.upcomingObligation, obligation.upcoming.daysUntilDue <= 3 {
            return .upcomingObligation
        }
        if candidates.payday != nil { return .payday }
        if candidates.patternAlert != nil { return .patternAlert }
        if candidates.subscriptionAudit != nil { return .subscriptionAudit }
        if candidates.weeklySummary != nil { return .weeklySummary }
        if candidates.wowMoment != nil { return .wowMoment }
        return nil
    }

    // MARK: - Generate

    /// Selectează și generează cel mai prioritar moment disponibil.
    ///
    /// - Throws: `OrchestratorError.noCandidatesAvailable` dacă nu există niciun context.
    /// - Throws: `OrchestratorError.buildFailed` dacă generarea eșuează (LLM sau JSON error).
    public func generate(from candidates: MomentCandidates, using llm: any LLMProvider) async throws -> MomentOutput {
        guard candidates.hasAnyCandidate else {
            throw OrchestratorError.noCandidatesAvailable
        }

        guard let selectedType = selectedType(from: candidates) else {
            throw OrchestratorError.noCandidatesAvailable
        }

        do {
            return try await buildSelected(type: selectedType, candidates: candidates, llm: llm)
        } catch let e as OrchestratorError {
            throw e
        } catch {
            throw OrchestratorError.buildFailed(momentType: selectedType, underlying: error)
        }
    }

    // MARK: - Private dispatch

    private func buildSelected(type: MomentType, candidates: MomentCandidates, llm: any LLMProvider) async throws -> MomentOutput {
        switch type {
        case .spiralAlert:
            guard let ctx = candidates.spiralAlert else { throw OrchestratorError.noCandidatesAvailable }
            return try await spiralBuilder.build(ctx, using: llm)
        case .canIAfford:
            guard let ctx = candidates.canIAfford else { throw OrchestratorError.noCandidatesAvailable }
            return try await canIAffordBuilder.build(ctx, using: llm)
        case .upcomingObligation:
            guard let ctx = candidates.upcomingObligation else { throw OrchestratorError.noCandidatesAvailable }
            return try await upcomingBuilder.build(ctx, using: llm)
        case .payday:
            guard let ctx = candidates.payday else { throw OrchestratorError.noCandidatesAvailable }
            return try await paydayBuilder.build(ctx, using: llm)
        case .patternAlert:
            guard let ctx = candidates.patternAlert else { throw OrchestratorError.noCandidatesAvailable }
            return try await patternBuilder.build(ctx, using: llm)
        case .subscriptionAudit:
            guard let ctx = candidates.subscriptionAudit else { throw OrchestratorError.noCandidatesAvailable }
            return try await subscriptionBuilder.build(ctx, using: llm)
        case .weeklySummary:
            guard let ctx = candidates.weeklySummary else { throw OrchestratorError.noCandidatesAvailable }
            return try await weeklyBuilder.build(ctx, using: llm)
        case .wowMoment:
            guard let ctx = candidates.wowMoment else { throw OrchestratorError.noCandidatesAvailable }
            return try await wowBuilder.build(ctx, using: llm)
        }
    }
}
