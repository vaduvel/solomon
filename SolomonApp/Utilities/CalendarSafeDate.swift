import Foundation

// MARK: - Calendar safe date construction
//
// FAZA A2 fix: `Calendar.date(bySetting: .day, value: 31, of: ...)` returnează
// `nil` în luni cu < 31 zile (februarie, aprilie, iunie, septembrie, noiembrie),
// iar fallback-urile `?? now` produc bug-uri financiare reale: ziua de salariu
// "dispare" în acele luni → Safe-to-Spend afișează salariul întreg ca disponibil.
//
// Acest helper clamp-uiește ziua la ultima zi a lunii când e necesar:
//   - paydayDay = 31 în februarie 2026 → 28 februarie 2026 (clamp)
//   - paydayDay = 29 în februarie 2027 (an non-bisect) → 28 februarie 2027
//   - paydayDay = 30 în aprilie → 30 aprilie (rămâne)

extension Calendar {

    /// Returnează data care reprezintă `dayOfMonth` în luna lui `referenceDate`.
    /// Dacă `dayOfMonth` depășește numărul de zile din lună, clamp-uiește la ultima zi.
    ///
    /// - Parameters:
    ///   - dayOfMonth: ziua dorită (1...31)
    ///   - referenceDate: data care identifică luna și anul țintă
    /// - Returns: o dată validă în luna referință, garantat non-nil dacă referință e validă.
    func safeDate(dayOfMonth: Int, in referenceDate: Date) -> Date {
        let comps = dateComponents([.year, .month], from: referenceDate)
        guard let year = comps.year, let month = comps.month else {
            return referenceDate
        }

        // Construim primul al lunii ca să aflăm câte zile are
        var firstOfMonth = DateComponents()
        firstOfMonth.year = year
        firstOfMonth.month = month
        firstOfMonth.day = 1
        guard let firstDate = date(from: firstOfMonth),
              let range = self.range(of: .day, in: .month, for: firstDate) else {
            return referenceDate
        }

        let lastDay = range.count            // 28, 29, 30 sau 31
        let clampedDay = min(max(dayOfMonth, 1), lastDay)

        var target = DateComponents()
        target.year = year
        target.month = month
        target.day = clampedDay
        return date(from: target) ?? referenceDate
    }
}
