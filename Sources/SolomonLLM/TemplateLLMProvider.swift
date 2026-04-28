import Foundation
import SolomonCore

// MARK: - TemplateLLMProvider
//
// Provider determinist care NU folosește LLM real. Parsează JSON-ul de context
// și interpolează cifrele cheie în template-uri RO predefinite per moment_type.
//
// Folosit în:
//   - Production fallback când Ollama/MLX nu e disponibil
//   - Demo mode pe iPhone fără server LLM rulat local
//   - First-launch experience (Wow Moment) imediat după onboarding
//
// Output-ul e SCURT, FACTUAL, cu diacritice. Nu pretinde că e generat de LLM —
// e un fallback safe care livrează valoare reală cu cifrele user-ului.

public final class TemplateLLMProvider: LLMProvider, @unchecked Sendable {

    public init() {}

    public func generate(
        systemPrompt: String,
        userContext: String,
        maxWords: Int
    ) async throws -> String {
        // Parsăm JSON-ul de context ca dictionary generic (e mai robust decât
        // să încercăm să decodăm fiecare tip strict — context coder e separat).
        guard let data = userContext.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Solomon procesează datele tale."
        }

        let momentType = (dict["moment_type"] as? String)?.lowercased() ?? "unknown"
        let userBlock = dict["user"] as? [String: Any]
        let name = (userBlock?["name"] as? String) ?? "prietene"
        let address = (userBlock?["addressing"] as? String) ?? "tu"
        let isFormal = (address == "dumneavoastra")

        let response: String
        switch momentType {
        case "wow_moment":            response = renderWowMoment(dict, name: name, formal: isFormal)
        case "can_i_afford":          response = renderCanIAfford(dict, name: name, formal: isFormal)
        case "payday":                response = renderPayday(dict, name: name, formal: isFormal)
        case "upcoming_obligation":   response = renderUpcoming(dict, name: name, formal: isFormal)
        case "pattern_alert":         response = renderPatternAlert(dict, name: name, formal: isFormal)
        case "subscription_audit":    response = renderSubscriptionAudit(dict, name: name, formal: isFormal)
        case "spiral_alert":          response = renderSpiralAlert(dict, name: name, formal: isFormal)
        case "weekly_summary":        response = renderWeeklySummary(dict, name: name, formal: isFormal)
        default:                      response = "Solomon analizează."
        }

        // Trim la maxWords dacă a depășit
        let words = response.split { $0.isWhitespace }
        if words.count > maxWords {
            return words.prefix(maxWords).joined(separator: " ") + "..."
        }
        return response
    }

    // MARK: - WOW Moment

    private func renderWowMoment(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let income = ctx["income"] as? [String: Any]
        let monthlyAvg = (income?["monthly_avg"] as? Int) ?? 0
        let spending = ctx["spending"] as? [String: Any]
        let totalLast30 = (spending?["total_last_30_days"] as? Int) ?? 0
        let positives = ctx["positives"] as? [String]
        let ghostSubs = ctx["ghost_subscriptions"] as? [[String: Any]] ?? []
        let ghostSavings = ghostSubs.reduce(0) { $0 + ((($1["amount_monthly"]) as? Int) ?? 0) }

        let salut = greeting(formal: formal)
        var lines: [String] = []

        lines.append("\(salut), \(name). Iată primul tău raport.")
        if monthlyAvg > 0 {
            lines.append("În medie ai \(monthlyAvg) RON pe lună din salariu.")
        }
        if totalLast30 > 0 {
            lines.append("În ultimele 30 zile ai cheltuit \(totalLast30) RON.")
        }
        if ghostSavings > 0 {
            let count = ghostSubs.count
            let plural = count == 1 ? "abonament fantomă" : "abonamente fantomă"
            lines.append("Am găsit \(count) \(plural) — economisești \(ghostSavings) RON/lună dacă le anulezi.")
        }
        if let positives = positives?.prefix(2), !positives.isEmpty {
            lines.append("Ce mergi bine: " + positives.joined(separator: "; ") + ".")
        }
        return lines.joined(separator: " ")
    }

    // MARK: - Can I Afford

    private func renderCanIAfford(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let query = ctx["query"] as? [String: Any]
        let amount = (query?["amount_requested"] as? Int) ?? 0
        let item = (query?["raw_text"] as? String) ?? "achiziția"
        let decision = ctx["decision"] as? [String: Any]
        let verdict = (decision?["verdict"] as? String) ?? "uncertain"
        let mathVisible = decision?["math_visible"] as? String

        switch verdict {
        case "yes":
            if let math = mathVisible {
                return "Da, \(name), poți cumpăra \(item) (\(amount) RON). \(math)."
            }
            return "Da, \(name), poți cumpăra \(item) (\(amount) RON) — încadrezi confortabil."
        case "tight":
            return "\(name), e strâns. \(amount) RON pentru \(item) îți lasă puțin până la salariu."
        case "no":
            let reason = (decision?["reason_short"] as? String) ?? "ar afecta obligațiile"
            return "Nu, \(name). \(amount) RON pentru \(item) \(reason)."
        default:
            return "Verific contul tău pentru \(item)..."
        }
    }

    // MARK: - Payday

    private func renderPayday(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let salary = ctx["salary"] as? [String: Any]
        let amount = (salary?["amount_received"] as? Int) ?? 0
        let allocation = ctx["auto_allocation"] as? [String: Any]
        let obligations = (allocation?["obligations_total"] as? Int) ?? 0
        let available = (allocation?["available_to_spend"] as? Int) ?? 0
        let perDay = (allocation?["available_per_day"] as? Int) ?? 0

        let salutStr = formal
            ? "Salariul dumneavoastră a intrat: \(amount) RON."
            : "Salariul a intrat: \(amount) RON."
        let obligStr = formal
            ? "\(obligations) RON merg pe obligații."
            : "\(obligations) RON merg pe obligații."
        var lines: [String] = [salutStr, " \(obligStr)"]
        if available > 0 && perDay > 0 {
            let ramStr = formal
                ? " Vă rămân \(available) RON disponibili — \(perDay) RON pe zi."
                : " Rămân \(available) RON disponibili — \(perDay) RON pe zi."
            lines.append(ramStr)
        }
        return lines.joined()
    }

    // MARK: - Upcoming Obligation

    private func renderUpcoming(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let upcoming = ctx["upcoming"] as? [String: Any]
        let oblName = (upcoming?["name"] as? String) ?? "factură"
        let amount = (upcoming?["amount"] as? Int) ?? 0
        let daysUntil = (upcoming?["days_until_due"] as? Int) ?? 0

        let adv = formal ? "Aveți" : "Ai"
        if daysUntil == 0 {
            return "\(name), \(oblName) (\(amount) RON) e scadent astăzi. \(adv) fondurile necesare?"
        }
        if daysUntil == 1 {
            return "\(name), \(oblName) (\(amount) RON) e scadent mâine."
        }
        return "\(name), \(oblName) (\(amount) RON) e scadent în \(daysUntil) zile."
    }

    // MARK: - Pattern Alert

    private func renderPatternAlert(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let pattern = ctx["pattern_detected"] as? [String: Any]
        let category = (pattern?["category"] as? String) ?? "cheltuieli"
        let percentage = (pattern?["percentage_of_total"] as? Int) ?? 0
        let amount = (pattern?["amount_total"] as? Int) ?? 0

        let verb = formal ? "reprezintă" : "reprezintă"
        let pron = formal ? "dumneavoastră" : "tale"
        if percentage > 0 && amount > 0 {
            return "\(name), \(category) \(verb) \(percentage)% din cheltuielile \(pron) (\(amount) RON). Media obișnuită e mai mică."
        }
        return "\(name), Solomon a observat un tipar nou la \(category)."
    }

    // MARK: - Subscription Audit

    private func renderSubscriptionAudit(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let totals = ctx["totals"] as? [String: Any]
        let monthly = (totals?["total_monthly"] as? Int) ?? 0
        let ghosts = ctx["ghost_subscriptions"] as? [[String: Any]] ?? []
        let savings = ghosts.reduce(0) { $0 + ((($1["amount_monthly"]) as? Int) ?? 0) }

        let pron = formal ? "dumneavoastră" : "tale"
        let verb = formal ? "Anulați-le" : "Anulează-le"
        if ghosts.isEmpty {
            return "\(name), abonamentele \(pron) sunt în regulă — \(monthly) RON/lună, toate folosite."
        }
        let plural = ghosts.count == 1 ? "abonament fantomă" : "abonamente fantomă"
        let consum = formal ? "vă consumă" : "îți consumă"
        return "\(name), \(ghosts.count) \(plural) \(consum) \(savings) RON/lună. \(verb) și economisiți \(savings * 12) RON pe an."
    }

    // MARK: - Spiral Alert

    private func renderSpiralAlert(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let severity = (ctx["severity"] as? String) ?? "medium"
        let rawSummary = (ctx["narrative_summary"] as? String) ?? "Soldul scade lună de lună."
        // Adaptăm pronumele din summary dacă e formal
        let summary = formal
            ? rawSummary.replacingOccurrences(of: "tău", with: "dumneavoastră")
                        .replacingOccurrences(of: "tăi", with: "dumneavoastră")
            : rawSummary
        let plan = ctx["recovery_plan"] as? [String: Any]
        let step1 = plan?["step1"] as? [String: Any]
        let action1 = (step1?["action"] as? String) ?? "Anulați cel mai mare abonament nefolosit"
        let primulPas = formal ? "Primul pas recomandat" : "Primul pas"
        let csalbRelevant = (ctx["csalb_relevant"] as? Bool) ?? false
        var msg = "\(name), atenție: \(summary) \(primulPas): \(action1)."
        if severity == "high" || severity == "critical", csalbRelevant {
            msg += " CSALB poate media gratuit cu băncile/IFN-urile."
        }
        return msg
    }

    // MARK: - Weekly Summary

    private func renderWeeklySummary(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let spending = ctx["spending"] as? [String: Any]
        let total = (spending?["total"] as? Int) ?? 0
        let smallWin = ctx["small_win"] as? [String: Any]
        let winText = (smallWin?["text"] as? String)

        let verb = formal ? "ați cheltuit" : "ai cheltuit"
        var msg = "\(name), săptămâna asta \(verb) \(total) RON."
        if let winText, !winText.isEmpty {
            msg += " \(winText)"
        }
        return msg
    }

    // MARK: - Helpers

    private func greeting(formal: Bool) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Bună dimineața"          // neutru RO — identic pt ambele
        case 12..<18: return formal ? "Bună ziua" : "Salut"
        case 18..<22: return "Bună seara"              // neutru RO — identic pt ambele
        default:      return formal ? "Salutare" : "Salut"
        }
    }
}
