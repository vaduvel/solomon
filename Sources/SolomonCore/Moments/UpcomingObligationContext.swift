import Foundation

public enum EstimationConfidence: String, Codable, Sendable, Hashable {
    case low, medium, high
}

public struct UpcomingObligationItem: Codable, Sendable, Hashable {
    public var name: String
    public var amountEstimated: Money
    public var dueDate: Date
    public var daysUntilDue: Int
    public var amountEstimationConfidence: EstimationConfidence
    public var basedOnHistory: String

    public init(name: String, amountEstimated: Money, dueDate: Date, daysUntilDue: Int,
                amountEstimationConfidence: EstimationConfidence, basedOnHistory: String) {
        self.name = name
        self.amountEstimated = amountEstimated
        self.dueDate = dueDate
        self.daysUntilDue = daysUntilDue
        self.amountEstimationConfidence = amountEstimationConfidence
        self.basedOnHistory = basedOnHistory
    }
}

public struct UpcomingObligationCashContext: Codable, Sendable, Hashable {
    public var currentBalance: Money
    public var afterPayment: Money
    public var daysUntilNextPayday: Int
    public var availablePerDayAfter: Money

    public init(currentBalance: Money, afterPayment: Money,
                daysUntilNextPayday: Int, availablePerDayAfter: Money) {
        self.currentBalance = currentBalance
        self.afterPayment = afterPayment
        self.daysUntilNextPayday = daysUntilNextPayday
        self.availablePerDayAfter = availablePerDayAfter
    }
}

public enum AssessmentTone: String, Codable, Sendable, Hashable {
    case reassuring
    case calm
    case alert
    case urgent
}

public struct UpcomingObligationAssessment: Codable, Sendable, Hashable {
    public var isAffordable: Bool
    public var isTight: Bool
    public var tone: AssessmentTone

    public init(isAffordable: Bool, isTight: Bool, tone: AssessmentTone) {
        self.isAffordable = isAffordable
        self.isTight = isTight
        self.tone = tone
    }
}

public struct WeekendWarning: Codable, Sendable, Hashable {
    public var isWeekendComing: Bool
    public var weekendAvgSpend: Money
    public var wouldCreateProblem: Bool

    public init(isWeekendComing: Bool, weekendAvgSpend: Money, wouldCreateProblem: Bool) {
        self.isWeekendComing = isWeekendComing
        self.weekendAvgSpend = weekendAvgSpend
        self.wouldCreateProblem = wouldCreateProblem
    }
}

// MARK: - Context principal (spec §6.5)

public struct UpcomingObligationContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var upcoming: UpcomingObligationItem
    public var context: UpcomingObligationCashContext
    public var assessment: UpcomingObligationAssessment
    public var weekendWarning: WeekendWarning

    public init(user: MomentUser, upcoming: UpcomingObligationItem,
                context: UpcomingObligationCashContext,
                assessment: UpcomingObligationAssessment,
                weekendWarning: WeekendWarning) {
        self.momentType = .upcomingObligation
        self.user = user
        self.upcoming = upcoming
        self.context = context
        self.assessment = assessment
        self.weekendWarning = weekendWarning
    }
}
