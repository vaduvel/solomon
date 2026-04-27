import Foundation

/// Sume financiare în RON, modelate ca integer (fără bani).
///
/// Spec Solomon §6.1: „Sume în RON ca integer". Solomon v1 rotunjește
/// la cel mai apropiat RON la parse-time (din extras bancare, email).
/// Pentru calcule intermediare (medii, procente) folosește `Double`
/// și converteste înapoi la `Money` la sfârșit.
public struct Money: Hashable, Sendable, Codable, Comparable, ExpressibleByIntegerLiteral {
    /// Cantitate în RON, semnată. Negativ = ieșire/datorie, pozitiv = intrare/economie.
    public let amount: Int

    public init(_ amount: Int) {
        self.amount = amount
    }

    public init(integerLiteral value: Int) {
        self.amount = value
    }

    /// Construiește dintr-o valoare în „bani" (1/100 RON), rotunjind la cel mai apropiat RON.
    /// Ex: `Money.fromMinor(8450)` → `Money(85)`.
    public static func fromMinor(_ bani: Int) -> Money {
        let sign = bani < 0 ? -1 : 1
        let absRounded = (abs(bani) + 50) / 100
        return Money(sign * absRounded)
    }

    /// Construiește din `Double` (RON cu zecimale), rotunjind la cel mai apropiat RON.
    public static func fromRON(_ value: Double) -> Money {
        Money(Int(value.rounded(.toNearestOrEven)))
    }

    public var isZero: Bool { amount == 0 }
    public var isPositive: Bool { amount > 0 }
    public var isNegative: Bool { amount < 0 }

    public static func + (lhs: Money, rhs: Money) -> Money { Money(lhs.amount + rhs.amount) }
    public static func - (lhs: Money, rhs: Money) -> Money { Money(lhs.amount - rhs.amount) }
    public static func * (lhs: Money, rhs: Int) -> Money { Money(lhs.amount * rhs) }
    public static prefix func - (m: Money) -> Money { Money(-m.amount) }

    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.amount < rhs.amount }

    /// Encode/decode ca integer JSON, conform spec §6.1.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.amount = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(amount)
    }
}
