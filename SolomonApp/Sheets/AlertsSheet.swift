import SwiftUI

// MARK: - AlertsSheet
//
// Sheet deschis la apăsarea clopotelului din TodayView.
// Arată momentul curent + istoricul recent de momente Solomon.

struct AlertsSheet: View {

    @Environment(\.dismiss) private var dismiss

    let moments: [DisplayMoment]
    let currentMoment: DisplayMoment?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.solCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SolSpacing.lg) {
                        if let current = currentMoment {
                            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                                Label("Momentul curent", systemImage: "sparkles")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.solMuted)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                MomentCard(moment: current)
                            }
                        } else {
                            emptyState
                        }

                        if moments.count > 1 {
                            VStack(alignment: .leading, spacing: SolSpacing.sm) {
                                Label("Istoricul alertelor", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.solMuted)
                                    .textCase(.uppercase)
                                    .tracking(0.8)

                                ForEach(moments.dropFirst()) { moment in
                                    historyRow(moment)
                                }
                            }
                        }

                        Spacer(minLength: SolSpacing.hh)
                    }
                    .padding(.horizontal, SolSpacing.screenHorizontal)
                    .padding(.top, SolSpacing.lg)
                }
            }
            .navigationTitle("Alerte Solomon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gata") { dismiss() }
                        .foregroundStyle(Color.solPrimary)
                }
            }
        }
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: SolSpacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 44))
                .foregroundStyle(Color.solMuted)
            Text("Nicio alertă activă")
                .font(.solH2)
                .foregroundStyle(Color.solForeground)
            Text("Solomon monitorizează datele tale și te avertizează când detectează ceva important.")
                .font(.solBody)
                .foregroundStyle(Color.solMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SolSpacing.xxxl)
    }

    // MARK: - History row

    @ViewBuilder
    private func historyRow(_ moment: DisplayMoment) -> some View {
        HStack(alignment: .top, spacing: SolSpacing.md) {
            Image(systemName: moment.systemIconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(moment.accentColor)
                .frame(width: 32, height: 32)
                .background(moment.accentColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(moment.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.solForeground)
                    Spacer()
                    Text(moment.timeAgoString)
                        .font(.caption)
                        .foregroundStyle(Color.solMuted)
                }
                Text(moment.llmResponse)
                    .font(.footnote)
                    .foregroundStyle(Color.solMuted)
                    .lineLimit(3)
            }
        }
        .padding(SolSpacing.base)
        .background(Color.solCard)
        .clipShape(RoundedRectangle(cornerRadius: SolRadius.lg, style: .continuous))
    }
}

#Preview {
    AlertsSheet(moments: [], currentMoment: nil)
        .preferredColorScheme(.dark)
}
