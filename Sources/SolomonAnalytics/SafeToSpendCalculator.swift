import Foundation
import SolomonCore

/// Output al `SafeToSpendCalculator`.
public struct SafeToSpendBudget: Sendable, Hashable, Codable {
    public var currentBalance: Money
    public var obligationsRemaining: Money
    public var availableAfterObligations: Money
    /// Buffer recomandat (10% din `availableAfterObligations`, min 50 RON).
    public var bufferRecommended: Money
    public var availableAfterBuffer: Money
    public var daysUntilNextPayday: Int
    public var availablePerDay: Money
    public var availablePerDayAfterBuffer: Money
    public var velocityRONPerDay: Money
    public var daysUntilCritical: Int?

    public init(currentBalance: Money, obligationsRemaining: Money,
                availableAfterObligations: Money, bufferRecommended: Money,
                availableAfterBuffer: Money, daysUntilNextPayday: Int,
                availablePerDay: Money, availablePerDayAfterBuffer: Money,
                velocityRONPerDay: Money, daysUntilCritical: Int?) {
        self.currentBalance = currentBalance
        self.obligationsRemaining = obligationsRemaining
        self.availableAfterObligations = availableAfterObligations
        self.bufferRecommended = bufferRecommended
        self.availableAfterBuffer = availableAfterBuffer
        self.daysUntilNextPayday = daysUntilNextPayday
        self.availablePerDay = availablePerDay
        self.availablePerDayAfterBuffer = availablePerDayAfterBuffer
        self.velocityRONPerDay = velocityRONPerDay
        self.daysUntilCritical = daysUntilCritical
    }

    /// True dacă bugetul e foarte strâns (≤ 30 RON/zi sau ≤ 5 zile critice).
    public var isTight: Bool {
        if availablePerDay.amount <= 30 { return true }
        if let critical = daysUntilCritical, critical <= 5 { return true }
        return false
    }

    /// Răspunde la întrebarea „pot să cheltui X astăzi?".
    public func verdict(for amount: Money) -> Verdict {
        let projectedAvailable = availableAfterObligations - amount
        if projectedAvailable.isNegative {
            return .no(reason: .wouldBreakObligation)
        }
        let projectedPerDay = daysUntilNextPayday > 0
            ? Money(projectedAvailable.amount / daysUntilNextPayday)
            : projectedAvailable
        if projectedPerDay.amount < 20 {
            return .yesWithCaution(reason: .tightButWorkable, projectedPerDay: projectedPerDay)
        }
        if projectedPerDay.amount < 50 {
            return .yesWithCaution(reason: .tightButWorkable, projectedPerDay: projectedPerDay)
        }
        return .yes(projectedPerDay: projectedPerDay)
    }

    public enum Verdict: Sendable, Hashable {
        case yes(projectedPerDay: Money)
        case yesWithCaution(reason: CanIAffordVerdictReason, projectedPerDay: Money)
        case no(reason: CanIAffordVerdictReason)

        public var isAffordable: Bool {
            switch self {
            case .yes, .yesWithCaution: return true
            case .no: return false
            }
        }

        public var asContextVerdict: CanIAffordVerdict {
            switch self {
            case .yes:             return .yes
            case .yesWithCaution:  return .yesWithCaution
            case .no:              return .no
            }
        }
    }
}

/// Calculează cât poate cheltui sigur utilizatorul azi (spec §7.2 modul 3).
public struct SafeToSpendCalculator: Sendable {

    public init() {}

    /// - Parameters:
    ///   - currentBalance: balanța bancară curentă.
    ///   - obligationsRemaining: obligații care încă vin în această perioadă.
    ///   - daysUntilNextPayday: nr de zile până la următorul salariu.
    ///   - velocityRONPerDay: rata medie zilnică de cheltuieli (din CashFlow).
    public func calculate(
        currentBalance: Money,
        obligationsRemaining: Money,
        daysUntilNextPayday: Int,
        velocityRONPerDay: Money = Money(0)
    ) -> SafeToSpendBudget {
        let safeDays = max(daysUntilNextPayday, 1)
        let afterObligations = currentBalance - obligationsRemaining

        let bufferRaw = afterObligations.amount / 10
        let buffer = Money(max(bufferRaw, afterObligations.isPositive ? 50 : 0))
        let afterBuffer = afterObligations - buffer

        let perDay = Money(max(0, afterObligations.amount) / safeDays)
        let perDayAfterBuffer = Money(max(0, afterBuffer.amount) / safeDays)

        let daysUntilCritical: Int?
        if velocityRONPerDay.amount > 0 && afterObligations.isPositive {
            let est = afterObligations.amount / velocityRONPerDay.amount
            daysUntilCritical = est < daysUntilNextPayday ? est : nil
        } else if afterObligations.isNegative {
            daysUntilCritical = 0
        } else {
            daysUntilCritical = nil
        }

        return SafeToSpendBudget(
            currentBalance: currentBalance,
            obligationsRemaining: obligationsRemaining,
            availableAfterObligations: afterObligations,
            bufferRecommended: buffer,
            availableAfterBuffer: afterBuffer,
            daysUntilNextPayday: daysUntilNextPayday,
            availablePerDay: perDay,
            availablePerDayAfterBuffer: perDayAfterBuffer,
            velocityRONPerDay: velocityRONPerDay,
            daysUntilCritical: daysUntilCritical
        )
    }
}
