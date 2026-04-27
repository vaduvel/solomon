import Foundation

/// Formatare sume în română (spec: „1.247 RON", separator de mii „." și sufix „RON").
public enum RomanianMoneyFormatter {

    public enum Style: Sendable {
        /// „1.247 RON" — varianta default folosită în Solomon.
        case short
        /// „1.247" — fără sufix, pentru contexte unde e clar din UI.
        case bareNumber
        /// „1,2k RON" / „1,2 mil RON" — pentru hero numbers compacte.
        case compact
        /// „1.247 lei" — pentru contexte mai colocviale.
        case lei
    }

    public static func format(_ money: Money, style: Style = .short) -> String {
        format(money.amount, style: style)
    }

    public static func format(_ amount: Int, style: Style = .short) -> String {
        switch style {
        case .short:
            return "\(thousands(amount)) RON"
        case .bareNumber:
            return thousands(amount)
        case .compact:
            return compact(amount, suffix: "RON")
        case .lei:
            return "\(thousands(amount)) lei"
        }
    }

    // MARK: - Internals

    /// Inserează „." ca separator de mii în reprezentarea decimală RO.
    public static func thousands(_ amount: Int) -> String {
        let sign = amount < 0 ? "-" : ""
        var digits = String(abs(amount))
        var groups: [String] = []
        while digits.count > 3 {
            let split = digits.index(digits.endIndex, offsetBy: -3)
            groups.insert(String(digits[split...]), at: 0)
            digits = String(digits[..<split])
        }
        groups.insert(digits, at: 0)
        return sign + groups.joined(separator: ".")
    }

    private static func compact(_ amount: Int, suffix: String) -> String {
        let magnitude = Swift.abs(amount)
        if magnitude >= 1_000_000 {
            return "\(decimal(Double(amount) / 1_000_000)) mil \(suffix)"
        }
        if magnitude >= 1_000 {
            return "\(decimal(Double(amount) / 1_000))k \(suffix)"
        }
        return "\(amount) \(suffix)"
    }

    private static func decimal(_ value: Double) -> String {
        // 1 zecimală cu virgulă RO; ascunde „,0" inutil.
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",")
    }
}
