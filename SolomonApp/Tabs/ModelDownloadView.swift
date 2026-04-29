import SwiftUI
import SolomonLLM

// MARK: - ModelDownloadView
//
// Vizualizează state-ul modelului LLM on-device:
//   - Nedescărcat: CTA "Descarcă Gemma" cu mărimea aprox.
//   - Downloading: progress bar live
//   - Activ: confirmare + buton "Șterge model"
//   - Eroare: re-try
//
// Wired în Settings → "Modelul LLM".

struct ModelDownloadView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var service = ModelDownloadService.shared
    @State private var showConfirmDelete: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {

                        heroCard
                        modelPickerSection
                        actionsSection
                        infoSection

                        Spacer()
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                    .padding(.bottom, SolSpacing.hh)
                }
            }
            .navigationTitle("Modelul LLM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Închide") { dismiss() }
                        .foregroundStyle(Color.solMuted)
                }
            }
            .alert("Ștergi modelul?", isPresented: $showConfirmDelete) {
                Button("Anulează", role: .cancel) {}
                Button("Șterge", role: .destructive) {
                    Task { await service.deleteCurrentModel() }
                }
            } message: {
                Text("Modelul descărcat va fi șters de pe device. Răspunsurile Solomon vor folosi template fallback până redescărcăm modelul.")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var heroCard: some View {
        VStack(spacing: SolSpacing.sm) {
            IconContainer(
                systemName: heroIconName,
                variant: heroIconVariant,
                size: 64,
                iconSize: 28
            )
            Text(service.config.displayName)
                .font(.solH1)
                .foregroundStyle(Color.solForeground)
            Text(service.stateLabel)
                .font(.solBody)
                .foregroundStyle(Color.solMuted)

            if case .downloading = service.state {
                NeonProgressBar(
                    progress: service.stateProgress,
                    variant: .info,
                    label: "Descărcare",
                    trailing: "\(Int(service.stateProgress * 100))%"
                )
                .padding(.top, SolSpacing.md)
            }
        }
        .padding(SolSpacing.cardHero)
        .frame(maxWidth: .infinity)
        .solGlassCard()
    }

    @ViewBuilder
    private var modelPickerSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("MODEL")
                .font(.solMicro)
                .foregroundStyle(Color.solMuted)
                .tracking(1.2)

            VStack(spacing: SolSpacing.sm) {
                modelOption(
                    title: "Gemma 2 (2B)",
                    subtitle: "~1.5 GB · iPhone 14+",
                    config: .gemmaE2B
                )
                modelOption(
                    title: "Gemma 3 (4B) ✦ Recomandat",
                    subtitle: "~2.8 GB · iPhone 15 Pro+",
                    config: .gemma3_4b
                )
                modelOption(
                    title: "Gemma 2 (9B)",
                    subtitle: "~5 GB · iPhone 15 Pro+",
                    config: .gemmaE4B
                )
            }
        }
    }

    @ViewBuilder
    private func modelOption(
        title: String,
        subtitle: String,
        config: MLXLLMProvider.Config
    ) -> some View {
        let isSelected = service.config.modelId == config.modelId
        Button {
            service.setConfig(config)
        } label: {
            HStack(spacing: SolSpacing.md) {
                IconContainer(
                    systemName: "cpu.fill",
                    variant: isSelected ? .neon : .tinted,
                    size: 36,
                    iconSize: 14
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.solBodyBold)
                        .foregroundStyle(Color.solForeground)
                    Text(subtitle)
                        .font(.solCaption)
                        .foregroundStyle(Color.solMuted)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.solPrimary)
                }
            }
            .padding(SolSpacing.base)
            .background(isSelected ? Color.solPrimary.opacity(0.10) : Color.solCard)
            .clipShape(RoundedRectangle(cornerRadius: SolRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: SolRadius.xl)
                    .stroke(isSelected ? Color.solPrimary : Color.solBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: SolSpacing.sm) {
            switch service.state {
            case .notDownloaded:
                SolomonButton(
                    "Descarcă \(service.config.displayName) (\(service.configSizeFormatted))",
                    icon: "arrow.down.circle.fill"
                ) {
                    Task { await service.startDownloadAndLoad() }
                }
            case .downloading:
                SolomonButton("Descărcare în curs...", isLoading: true) {}
                    .disabled(true)
            case .loaded:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.solPrimary)
                    Text("Modelul e activ pe device")
                        .font(.solBody)
                        .foregroundStyle(Color.solForeground)
                }
                .padding(SolSpacing.base)
                .frame(maxWidth: .infinity)
                .solCard()

                SolomonButton("Șterge modelul", style: .danger, icon: "trash") {
                    showConfirmDelete = true
                }
            case .loadFailed(let reason):
                Text(reason)
                    .font(.solCaption)
                    .foregroundStyle(Color.solDestructive)
                SolomonButton("Reîncearcă", icon: "arrow.clockwise") {
                    Task { await service.startDownloadAndLoad() }
                }
            }
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: SolSpacing.sm) {
            Text("DETALII")
                .font(.solMicro)
                .foregroundStyle(Color.solMuted)
                .tracking(1.2)

            VStack(spacing: SolSpacing.sm) {
                infoRow(label: "Mărime aproximativă", value: service.configSizeFormatted)
                infoRow(label: "Pe device", value: service.sizeOnDiskFormatted)
                infoRow(label: "Repository", value: service.config.modelId, isSmall: true)
            }
            .padding(SolSpacing.cardSmall)
            .solCard()

            Text("Modelul rulează 100% pe device. Datele tale nu părăsesc telefonul.")
                .font(.solCaption)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, SolSpacing.sm)
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String, isSmall: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.solCaption)
                .foregroundStyle(Color.solMuted)
            Spacer()
            Text(value)
                .font(isSmall ? .solCaption : .solBody)
                .foregroundStyle(Color.solForeground)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    // MARK: - Helpers

    private var heroIconName: String {
        switch service.state {
        case .loaded:           return "checkmark.shield.fill"
        case .downloading:      return "arrow.down.circle.fill"
        case .loadFailed:       return "exclamationmark.triangle.fill"
        case .notDownloaded:    return "cpu"
        }
    }

    private var heroIconVariant: IconContainer.Variant {
        switch service.state {
        case .loaded:           return .neon
        case .downloading:      return .cyan
        case .loadFailed:       return .danger
        case .notDownloaded:    return .tinted
        }
    }
}

#Preview {
    ModelDownloadView()
        .preferredColorScheme(.dark)
}
