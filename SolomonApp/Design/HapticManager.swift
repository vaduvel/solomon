import SwiftUI
import UIKit

// MARK: - HapticManager
//
// Wrapper Apple HIG pentru haptic feedback. Folosește SensoryFeedback API
// pentru iOS 17+ via .sensoryFeedback(...) modifier, plus UIKit generators
// pentru control imperativ (din ViewModels / async tasks).

@MainActor
public enum Haptics {

    // MARK: - Notification feedback

    /// Operation succeeded (save complete, action confirmed)
    public static func success() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.success)
    }

    /// Validation issue, soft warning
    public static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.warning)
    }

    /// Operation failed
    public static func error() {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        g.notificationOccurred(.error)
    }

    // MARK: - Impact feedback

    /// Light tap (toggle, picker change)
    public static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        g.impactOccurred()
    }

    /// Medium tap (button tap, sheet open)
    public static func medium() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        g.impactOccurred()
    }

    /// Heavy tap (confirmation, important action)
    public static func heavy() {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        g.impactOccurred()
    }

    /// Soft impact — subtle (iOS 13+)
    public static func soft() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.prepare()
        g.impactOccurred()
    }

    /// Rigid impact — sharp (iOS 13+)
    public static func rigid() {
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.prepare()
        g.impactOccurred()
    }

    // MARK: - Selection feedback

    /// Selection changed (segmented control, picker scroll)
    public static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.prepare()
        g.selectionChanged()
    }
}
