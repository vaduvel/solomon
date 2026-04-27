import Foundation

/// Formatare date în română — luni, zile, ordinal — fără să depindem de Locale,
/// astfel încât output-ul Solomon să fie deterministic indiferent de setările device-ului.
public enum RomanianDateFormatter {

    public enum Style: Sendable {
        /// „luni"
        case dayOfWeek
        /// „15 aprilie"
        case dayMonth
        /// „15 aprilie 2026"
        case full
        /// „luni, 15 aprilie"
        case dayOfWeekDayMonth
        /// „2026-04-15" (ISO, pentru log/debug)
        case iso
    }

    public static func format(_ date: Date, style: Style, calendar: Calendar = .gregorianRO) -> String {
        let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let day = comps.day ?? 1
        let month = monthName(comps.month ?? 1)
        let year = comps.year ?? 0
        let weekday = weekdayName(comps.weekday ?? 1)

        switch style {
        case .dayOfWeek:           return weekday
        case .dayMonth:            return "\(day) \(month)"
        case .full:                return "\(day) \(month) \(year)"
        case .dayOfWeekDayMonth:   return "\(weekday), \(day) \(month)"
        case .iso:                 return String(format: "%04d-%02d-%02d", year, comps.month ?? 1, day)
        }
    }

    /// Forma ordinală a unei zile a lunii: „pe data 15".
    public static func dayOrdinal(_ day: Int) -> String {
        "data \(day)"
    }

    /// Forma „pe ziua de marți" pentru un weekday (1=Sun ... 7=Sat în Calendar.weekday).
    public static func dayOfWeekPhrase(_ weekday: Int) -> String {
        "ziua de \(weekdayName(weekday))"
    }

    // MARK: - Internals

    public static func monthName(_ month: Int) -> String {
        switch month {
        case 1:  return "ianuarie"
        case 2:  return "februarie"
        case 3:  return "martie"
        case 4:  return "aprilie"
        case 5:  return "mai"
        case 6:  return "iunie"
        case 7:  return "iulie"
        case 8:  return "august"
        case 9:  return "septembrie"
        case 10: return "octombrie"
        case 11: return "noiembrie"
        case 12: return "decembrie"
        default: return ""
        }
    }

    /// Calendar.weekday: 1 = duminică, 2 = luni, ..., 7 = sâmbătă.
    public static func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "duminică"
        case 2: return "luni"
        case 3: return "marți"
        case 4: return "miercuri"
        case 5: return "joi"
        case 6: return "vineri"
        case 7: return "sâmbătă"
        default: return ""
        }
    }
}

public extension Calendar {
    /// Calendar gregorian configurat pentru fus orar București, săptămâna începe luni.
    static var gregorianRO: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Bucharest") ?? .current
        cal.firstWeekday = 2 // Monday
        cal.minimumDaysInFirstWeek = 4 // ISO 8601
        return cal
    }
}
