import Testing
import Foundation
@testable import SolomonCore

@Suite struct SolomonKeyStrategyTests {

    // MARK: - camelToSnake

    @Test func basicCamelCaseConversion() {
        #expect(SolomonKeyStrategy.camelToSnake("monthlyAvg") == "monthly_avg")
        #expect(SolomonKeyStrategy.camelToSnake("incomeConsumptionRatio") == "income_consumption_ratio")
        #expect(SolomonKeyStrategy.camelToSnake("isHigherThanAverage") == "is_higher_than_average")
    }

    @Test func numericSuffixIsSeparated() {
        // Spec §6.2: „overdraft_used_count_180d" — underscore între count și 180.
        #expect(SolomonKeyStrategy.camelToSnake("overdraftUsedCount180d") == "overdraft_used_count_180d")
        #expect(SolomonKeyStrategy.camelToSnake("amountTotal180d") == "amount_total_180d")
    }

    @Test func digitFollowedByLetterStaysAttached() {
        // „180d" rămâne împreună (spec stil).
        #expect(SolomonKeyStrategy.camelToSnake("count180d") == "count_180d")
    }

    @Test func alreadyLowercaseIsUntouched() {
        #expect(SolomonKeyStrategy.camelToSnake("today") == "today")
        #expect(SolomonKeyStrategy.camelToSnake("score") == "score")
    }

    @Test func acronymsLikeIfnAndBnplStayLowercase() {
        // Acronyms se scriu în Swift ca camelCase normal (loansIfn / loansBank), nu cu URL/IFN UPPERCASE.
        #expect(SolomonKeyStrategy.camelToSnake("noIfn") == "no_ifn")
    }

    // MARK: - snakeToCamel

    @Test func basicSnakeToCamelConversion() {
        #expect(SolomonKeyStrategy.snakeToCamel("monthly_avg") == "monthlyAvg")
        #expect(SolomonKeyStrategy.snakeToCamel("income_consumption_ratio") == "incomeConsumptionRatio")
    }

    @Test func numericSegmentsKeepLowercase() {
        #expect(SolomonKeyStrategy.snakeToCamel("overdraft_used_count_180d") == "overdraftUsedCount180d")
        #expect(SolomonKeyStrategy.snakeToCamel("amount_total_180d") == "amountTotal180d")
    }

    @Test func roundTripIsSymmetric() {
        let originals = [
            "monthlyAvg",
            "overdraftUsedCount180d",
            "amountTotal180d",
            "isHigherThanAverage",
            "obligationsToIncomeRatio",
            "rentToIncomeHealthy",
            "vsLastMonthDirection"
        ]
        for original in originals {
            let snake = SolomonKeyStrategy.camelToSnake(original)
            let restored = SolomonKeyStrategy.snakeToCamel(snake)
            #expect(restored == original, "Round-trip eșuat pentru '\(original)' → '\(snake)' → '\(restored)'")
        }
    }

    // MARK: - End-to-end with encoder

    @Test func wowSpendingJsonMatchesSpec() throws {
        let spending = WowSpending(
            monthlyAvg: 4_218,
            incomeConsumptionRatio: 0.94,
            monthlyBalanceTrend: .barelyBreakeven,
            cardCreditUsed: false,
            overdraftUsedCount180d: 0
        )
        let json = try SolomonContextCoder.encodeAsJSONString(spending)
        // Trebuie să conțină EXACT cheia din spec.
        #expect(json.contains("\"overdraft_used_count_180d\":0"))
        #expect(json.contains("\"monthly_avg\":4218"))
        #expect(json.contains("\"income_consumption_ratio\":0.94"))
        #expect(json.contains("\"monthly_balance_trend\":\"barely_breakeven\""))
    }

    @Test func outlierJsonMatchesSpec() throws {
        let outlier = OutlierItem(
            rank: 2, type: .categoryConcentration, category: .foodDelivery,
            merchant: "Glovo", amountTotal180d: 7_480, amountMonthlyAvg: 1_247,
            contextPhrase: "media lunară 1.247 RON, 28% din salariu",
            contextComparison: "echivalent cu o vacanță de 7 zile la munte"
        )
        let json = try SolomonContextCoder.encodeAsJSONString(outlier)
        #expect(json.contains("\"amount_total_180d\":7480"))
        #expect(json.contains("\"amount_monthly_avg\":1247"))
        #expect(json.contains("\"context_phrase\":\"media lunară 1.247 RON, 28% din salariu\""))
        #expect(json.contains("\"context_comparison\":\"echivalent cu o vacanță de 7 zile la munte\""))
    }
}
