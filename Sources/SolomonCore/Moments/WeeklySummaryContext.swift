import Foundation

public struct WeekRange: Codable, Sendable, Hashable {
    public var start: Date
    public var end: Date
    public var weekNumber: Int

    public init(start: Date, end: Date, weekNumber: Int) {
        self.start = start
        self.end = end
        self.weekNumber = weekNumber
    }
}

public enum SpendingTrendDirection: String, Codable, Sendable, Hashable {
    case below          = "below"
    case slightlyBelow  = "slightly_below"
    case onAverage      = "on_average"
    case slightlyAbove  = "slightly_above"
    case above          = "above"
}

public struct WeeklySpendingBlock: Codable, Sendable, Hashable {
    public var total: Money
    public var vsWeeklyAvg: Money
    public var diffPct: Int
    public var direction: SpendingTrendDirection

    public init(total: Money, vsWeeklyAvg: Money, diffPct: Int, direction: SpendingTrendDirection) {
        self.total = total
        self.vsWeeklyAvg = vsWeeklyAvg
        self.diffPct = diffPct
        self.direction = direction
    }
}

public enum WeeklyHighlightType: String, Codable, Sendable, Hashable {
    case biggestExpense           = "biggest_expense"
    case budgetKept               = "budget_kept"
    case noIFNNoBNPLTemptation    = "no_ifn_no_bnpl_temptation"
    case smallWinNoticed          = "small_win_noticed"
    case newRecurringDetected     = "new_recurring_detected"
    case categoryDrift            = "category_drift"
}

public struct WeeklyHighlight: Codable, Sendable, Hashable {
    public var type: WeeklyHighlightType
    public var category: TransactionCategory?
    public var amount: Money?
    public var context: String

    public init(type: WeeklyHighlightType, category: TransactionCategory? = nil,
                amount: Money? = nil, context: String) {
        self.type = type
        self.category = category
        self.amount = amount
        self.context = context
    }
}

public struct UpcomingObligationRef: Codable, Sendable, Hashable {
    public var name: String
    public var amount: Money
    /// Numele zilei în română („marți", „vineri").
    public var day: String

    public init(name: String, amount: Money, day: String) {
        self.name = name
        self.amount = amount
        self.day = day
    }
}

public struct CalendarEventRef: Codable, Sendable, Hashable {
    public var name: String
    public var estimatedCost: Money
    public var date: String

    public init(name: String, estimatedCost: Money, date: String) {
        self.name = name
        self.estimatedCost = estimatedCost
        self.date = date
    }
}

public struct NextWeekPreview: Codable, Sendable, Hashable {
    public var obligationsDue: [UpcomingObligationRef]
    public var eventsInCalendar: [CalendarEventRef]

    public init(obligationsDue: [UpcomingObligationRef], eventsInCalendar: [CalendarEventRef]) {
        self.obligationsDue = obligationsDue
        self.eventsInCalendar = eventsInCalendar
    }
}

public struct SmallWin: Codable, Sendable, Hashable {
    public var exists: Bool
    public var description: String?

    public init(exists: Bool, description: String? = nil) {
        self.exists = exists
        self.description = description
    }
}

// MARK: - Context principal (spec §6.9)

public struct WeeklySummaryContext: Codable, Sendable, Hashable {
    public let momentType: MomentType
    public var user: MomentUser
    public var week: WeekRange
    public var spending: WeeklySpendingBlock
    public var highlights: [WeeklyHighlight]
    public var nextWeekPreview: NextWeekPreview
    public var smallWin: SmallWin

    public init(user: MomentUser, week: WeekRange, spending: WeeklySpendingBlock,
                highlights: [WeeklyHighlight], nextWeekPreview: NextWeekPreview, smallWin: SmallWin) {
        self.momentType = .weeklySummary
        self.user = user
        self.week = week
        self.spending = spending
        self.highlights = highlights
        self.nextWeekPreview = nextWeekPreview
        self.smallWin = smallWin
    }
}
