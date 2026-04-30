import SwiftUI
import SolomonLLM

// MARK: - ModelDownloadView (Solomon DS · Claude Design)
//
// Vizualizează state-ul modelului LLM on-device cu design Solomon DS:
//   - Hero card mint cu badge ACTIV + label model curent + size + status
//   - Insight card explicând cum rulează AI-ul local + privacy
//   - Section header "MODELE DISPONIBILE"
//   - List card cu rows pentru fiecare model (Gemma E2B, Gemma 3 4B, Gemma E4B)
//   - Trailing: chip "ACTIV" mint sau buton glass "Descarcă" (sau progress bar)
//   - Footer note "Datele tale rămân pe telefon"
//
// Wired în Settings → "Modelul AI".

struct ModelDownloadView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var service = ModelDownloadService.shared
    @State private var showConfirmDelete: Bool = false

    private let allModels: [MLXLLMProvider.Config] = [
        .gemmaE2B,
        .gemma3_4b,
        .gemmaE4B
    ]

    var body: some View {
        ZStack {
            MeshBackground()

            ScrollView {
                VStack(spacing: 0) {

                    // Sheet handle
                    sheetHandle
                        .padding(.bottom, 4)

                    // Header (back + brand + title)
                    headerSection
                        .padding(.bottom, SolSpacing.xl)

                    // Hero card — model curent
                    heroCard
                        .padding(.bottom, SolSpacing.base)

                    // Privacy / info insight
                    privacyInsight
                        .padding(.bottom, SolSpacing.xl)

                    // Section header
                    SolSectionHeaderRow(
                        "MODELE DISPONIBILE",
                        meta: "\(allModels.count) disponibile"
                    )

                    // Models list
                    modelsListCard
                        .padding(.bottom, SolSpacing.base)

                    // Error state (dacă există)
                    if case .loadFailed(let reason) = service.state {
                        errorBanner(reason)
                            .padding(.bottom, SolSpacing.base)
                    }

                    // Footer note
                    footerNote
                        .padding(.top, SolSpacing.sm)
                        .padding(.bottom, SolSpacing.xl)
                }
                .padding(.horizontal, SolSpacing.xl)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Ștergi modelul?", isPresented: $showConfirmDelete) {
            Button("Anulează", role: .cancel) {}
            Button("Șterge", role: .destructive) {
                Task { await service.deleteCurrentModel() }
            }
        } message: {
            Text("Modelul descărcat va fi șters de pe device. Răspunsurile Solomon vor folosi template fallback până redescărcăm modelul.")
        }
    }

    // MARK: - Sheet handle

    @ViewBuilder
    private var sheetHandle: some View {
        HStack {
            Spacer()
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 5)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Header (back + brand + title)

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            SolBackButton { dismiss() }

            VStack(alignment: .leading, spacing: 4) {
                Text("SOLOMON · LLM")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .tracking(1.4)
                Text("Modelul AI")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-0.4)
            }
            Spacer()
        }
        .padding(.top, SolSpacing.sm)
    }

    // MARK: - Hero card

    @ViewBuilder
    private var heroCard: some View {
        SolHeroCard(accent: .mint) {
            VStack(alignment: .leading, spacing: 0) {
                // Top label
                SolHeroLabel(heroLabel)
                    .padding(.top, 4)

                // Model name big
                Text(service.config.displayName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .tracking(-1.0)
                    .padding(.top, 6)
                    .shadow(color: Color.solMintExact.opacity(0.18), radius: 30)

                // Meta row: size · status
                HStack(spacing: 8) {
                    Text(service.configSizeFormatted)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 3, height: 3)
                    Text(service.stateLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(heroStatusColor)
                }
                .padding(.top, 10)
                .padding(.bottom, 18)

                // Action row
                heroActionRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } badge: {
            SolHeroBadge(heroBadgeLabel, accent: heroBadgeAccent)
        }
    }

    @ViewBuilder
    private var heroActionRow: some View {
        switch service.state {
        case .loaded:
            HStack(spacing: 8) {
                Button {
                    Haptics.light()
                    showConfirmDelete = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Șterge model")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.solRoseExact)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.solRoseExact.opacity(0.10))
                    )
                    .overlay(
                        Capsule().stroke(Color.solRoseExact.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                Spacer()
            }
        case .downloading:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Descărcare")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .tracking(0.4)
                    Spacer()
                    Text("\(Int(service.stateProgress * 100))%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.solMintLight)
                        .monospacedDigit()
                }
                SolLinearProgress(
                    progress: CGFloat(service.stateProgress),
                    accent: .mint,
                    height: 6,
                    glow: true
                )
            }
        case .notDownloaded:
            SolPrimaryButton("Descarcă \(service.configSizeFormatted)", accent: .mint, fullWidth: true) {
                Task { await service.startDownloadAndLoad() }
            }
        case .loadFailed:
            SolPrimaryButton("Reîncearcă descărcarea", accent: .mint, fullWidth: true) {
                Task { await service.startDownloadAndLoad() }
            }
        }
    }

    // MARK: - Privacy insight

    @ViewBuilder
    private var privacyInsight: some View {
        SolInsightCard(
            icon: "lock.shield.fill",
            label: "SOLOMON · INFO",
            timestamp: "on-device",
            accent: .mint
        ) {
            Text("AI-ul rulează 100% local pe iPhone, folosind Apple Silicon (Metal). Conversațiile, sumele și categoriile tale nu pleacă niciodată de pe telefon — fără cloud, fără tracking, fără terți.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Models list

    @ViewBuilder
    private var modelsListCard: some View {
        SolListCard {
            ForEach(Array(allModels.enumerated()), id: \.offset) { index, cfg in
                modelRow(for: cfg)
                if index < allModels.count - 1 {
                    SolHairlineDivider()
                }
            }
        }
    }

    @ViewBuilder
    private func modelRow(for cfg: MLXLLMProvider.Config) -> some View {
        let isSelected = service.config.modelId == cfg.modelId
        let isDownloading = isSelected && {
            if case .downloading = service.state { return true } else { return false }
        }()

        Button {
            Haptics.light()
            service.setConfig(cfg)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(SolAccent.mint.iconGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(Color.solMintExact.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.solMintExact)
                }
                .frame(width: 36, height: 36)

                // Title + sub
                VStack(alignment: .leading, spacing: 2) {
                    Text(cfg.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                    Text(rowSubtitle(for: cfg))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                // Trailing
                if isDownloading {
                    progressTrailing
                } else if isSelected, case .loaded = service.state {
                    SolChip("ACTIV", kind: .mint)
                } else {
                    downloadGlassButton(for: cfg)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var progressTrailing: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(Int(service.stateProgress * 100))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.solMintLight)
                .monospacedDigit()
            SolLinearProgress(
                progress: CGFloat(service.stateProgress),
                accent: .mint,
                height: 4,
                glow: true
            )
            .frame(width: 80)
        }
    }

    @ViewBuilder
    private func downloadGlassButton(for cfg: MLXLLMProvider.Config) -> some View {
        Button {
            Haptics.medium()
            service.setConfig(cfg)
            Task { await service.startDownloadAndLoad() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 11, weight: .semibold))
                Text("Descarcă")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.white.opacity(0.05))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error banner

    @ViewBuilder
    private func errorBanner(_ reason: String) -> some View {
        SolInsightCard(
            icon: "exclamationmark.triangle.fill",
            label: "SOLOMON · EROARE",
            timestamp: nil,
            accent: .rose
        ) {
            Text(reason)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "iphone")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.35))
            Text("Datele tale rămân pe telefon")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var heroLabel: String {
        switch service.state {
        case .loaded:           return "MODEL ACTIV · ON-DEVICE"
        case .downloading:      return "DESCĂRCARE ÎN CURS"
        case .loadFailed:       return "MODEL · EROARE"
        case .notDownloaded:    return "MODEL · NEDESCĂRCAT"
        }
    }

    private var heroBadgeLabel: String {
        switch service.state {
        case .loaded:           return "ACTIV"
        case .downloading:      return "DESCARC"
        case .loadFailed:       return "EROARE"
        case .notDownloaded:    return "OFF"
        }
    }

    private var heroBadgeAccent: SolAccent {
        switch service.state {
        case .loaded:           return .mint
        case .downloading:      return .blue
        case .loadFailed:       return .rose
        case .notDownloaded:    return .amber
        }
    }

    private var heroStatusColor: Color {
        switch service.state {
        case .loaded:           return .solMintLight
        case .downloading:      return Color(red: 0x93/255, green: 0xC5/255, blue: 0xFD/255)
        case .loadFailed:       return .solRoseExact
        case .notDownloaded:    return .solAmberExact
        }
    }

    private func rowSubtitle(for cfg: MLXLLMProvider.Config) -> String {
        let size = ByteCountFormatter.string(fromByteCount: cfg.approximateSizeBytes, countStyle: .binary)
        switch cfg.modelId {
        case MLXLLMProvider.Config.gemmaE2B.modelId:
            return "\(size) · iPhone 14+"
        case MLXLLMProvider.Config.gemma3_4b.modelId:
            return "\(size) · iPhone 15 Pro+ · recomandat"
        case MLXLLMProvider.Config.gemmaE4B.modelId:
            return "\(size) · iPhone 15 Pro+"
        default:
            return size
        }
    }
}

#Preview {
    ModelDownloadView()
        .preferredColorScheme(.dark)
}
