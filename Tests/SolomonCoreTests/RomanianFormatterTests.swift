import Testing
import Foundation
@testable import SolomonCore

@Suite struct RomanianMoneyFormatterTests {

    @Test func formatsWithRomanianThousandsSeparator() {
        #expect(RomanianMoneyFormatter.format(Money(1_247)) == "1.247 RON")
        #expect(RomanianMoneyFormatter.format(Money(4_500)) == "4.500 RON")
        #expect(RomanianMoneyFormatter.format(Money(123_456)) == "123.456 RON")
        #expect(RomanianMoneyFormatter.format(Money(1_000_000)) == "1.000.000 RON")
    }

    @Test func smallNumbersDoNotGetSeparator() {
        #expect(RomanianMoneyFormatter.format(Money(80)) == "80 RON")
        #expect(RomanianMoneyFormatter.format(Money(999)) == "999 RON")
    }

    @Test func zeroAndNegative() {
        #expect(RomanianMoneyFormatter.format(Money(0)) == "0 RON")
        #expect(RomanianMoneyFormatter.format(Money(-1_500)) == "-1.500 RON")
    }

    @Test func bareNumberStyleHasNoSuffix() {
        #expect(RomanianMoneyFormatter.format(Money(1_247), style: .bareNumber) == "1.247")
    }

    @Test func leiStyleUsesLowercaseLei() {
        #expect(RomanianMoneyFormatter.format(Money(1_247), style: .lei) == "1.247 lei")
    }

    @Test func compactStyleAbbreviatesLargeNumbers() {
        #expect(RomanianMoneyFormatter.format(Money(1_200), style: .compact) == "1,2k RON")
        #expect(RomanianMoneyFormatter.format(Money(1_000), style: .compact) == "1k RON")
        #expect(RomanianMoneyFormatter.format(Money(1_500_000), style: .compact) == "1,5 mil RON")
    }
}

@Suite struct RomanianDateFormatterTests {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var comps = DateComponents()
        comps.year = y
        comps.month = m
        comps.day = d
        return Calendar.gregorianRO.date(from: comps) ?? Date()
    }

    @Test func monthNamesAreInRomanianWithDiacritics() {
        // Spec interzice cuvinte engleză. Lunile RO trebuie complete.
        #expect(RomanianDateFormatter.monthName(1)  == "ianuarie")
        #expect(RomanianDateFormatter.monthName(4)  == "aprilie")
        #expect(RomanianDateFormatter.monthName(8)  == "august")
        #expect(RomanianDateFormatter.monthName(12) == "decembrie")
    }

    @Test func weekdayNamesAreInRomanianWithDiacritics() {
        // Calendar.weekday: 1=duminică ... 7=sâmbătă
        #expect(RomanianDateFormatter.weekdayName(1) == "duminică")
        #expect(RomanianDateFormatter.weekdayName(2) == "luni")
        #expect(RomanianDateFormatter.weekdayName(3) == "marți")
        #expect(RomanianDateFormatter.weekdayName(7) == "sâmbătă")
    }

    @Test func dayMonthStyle() {
        let d = date(2026, 4, 15)
        #expect(RomanianDateFormatter.format(d, style: .dayMonth) == "15 aprilie")
    }

    @Test func fullStyle() {
        let d = date(2026, 4, 15)
        #expect(RomanianDateFormatter.format(d, style: .full) == "15 aprilie 2026")
    }

    @Test func isoStyle() {
        let d = date(2026, 4, 15)
        #expect(RomanianDateFormatter.format(d, style: .iso) == "2026-04-15")
    }

    @Test func dayOrdinalIsNaturalRomanian() {
        #expect(RomanianDateFormatter.dayOrdinal(15) == "data 15")
        #expect(RomanianDateFormatter.dayOrdinal(1) == "data 1")
    }

    @Test func gregorianROCalendarStartsOnMonday() {
        #expect(Calendar.gregorianRO.firstWeekday == 2)
        #expect(Calendar.gregorianRO.timeZone.identifier == "Europe/Bucharest")
    }
}
