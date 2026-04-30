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
        // WowSpending are doar monthlyAvg (cheltuieli medii lunare). Nu există total_last_30_days.
        let monthlySpending = (spending?["monthly_avg"] as? Int) ?? 0
        // ghost_subscriptions e un BLOC (count + monthly_total + items), nu array direct
        let ghostBlock = ctx["ghost_subscriptions"] as? [String: Any]
        let ghostCount = (ghostBlock?["count"] as? Int) ?? 0
        let ghostSavings = (ghostBlock?["monthly_total"] as? Int) ?? 0
        // positives e [{type, description, ...}], nu [String]
        let positivesArr = ctx["positives"] as? [[String: Any]] ?? []
        let positivesText = positivesArr.compactMap { $0["description"] as? String }.prefix(2)

        let salut = greeting(formal: formal)
        var lines: [String] = []

        lines.append("\(salut), \(name). Iată primul tău raport.")
        if monthlyAvg > 0 {
            lines.append("În medie ai \(monthlyAvg) RON pe lună din salariu.")
        }
        if monthlySpending > 0 {
            lines.append("Cheltuieli medii: \(monthlySpending) RON pe lună.")
        }
        if ghostCount > 0 && ghostSavings > 0 {
            let plural = ghostCount == 1 ? "abonament fantomă" : "abonamente fantomă"
            lines.append("Am găsit \(ghostCount) \(plural) — economisești \(ghostSavings) RON/lună dacă le anulezi.")
        }
        if !positivesText.isEmpty {
            lines.append("Ce mergi bine: " + positivesText.joined(separator: "; ") + ".")
        }
        return lines.joined(separator: " ")
    }

    // MARK: - Can I Afford

    private func renderCanIAfford(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        let query = ctx["query"] as? [String: Any]
        let amount = (query?["amount_requested"] as? Int) ?? 0
        // Preferăm merchantInferred peste rawText (textul întrebării completă)
        let merchant = query?["merchant_inferred"] as? String
        let category = (query?["category_inferred"] as? String)?.replacingOccurrences(of: "_", with: " ")
        let item = merchant ?? category ?? "achiziția"
        let decision = ctx["decision"] as? [String: Any]
        let verdict = (decision?["verdict"] as? String) ?? "uncertain"
        let mathVisible = decision?["math_visible"] as? String

        switch verdict {
        case "yes":
            if let math = mathVisible {
                return "Da, \(name), poți cumpăra de la \(item) (\(amount) RON). \(math)."
            }
            return "Da, \(name), poți cumpăra de la \(item) (\(amount) RON) — încadrezi confortabil."
        case "tight":
            return "\(name), e strâns. \(amount) RON la \(item) îți lasă puțin până la salariu."
        case "no":
            // Traducem verdictReason în română (cazuri din CanIAffordVerdictReason enum)
            let reasonRaw = (decision?["verdict_reason"] as? String) ?? ""
            let reason = translateVerdictReason(reasonRaw)
            return "Nu, \(name). \(amount) RON la \(item) — \(reason)."
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
        // JSON key e "amount_estimated" (camelCase → snake_case via SolomonContextCoder)
        let amount = (upcoming?["amount_estimated"] as? Int) ?? (upcoming?["amount"] as? Int) ?? 0
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
        // Câmpurile reale: amountPeriod (suma observată) + vsBudgetPct (% peste medie)
        let amount = (pattern?["amount_period"] as? Int) ?? 0
        let vsBudgetPct = (pattern?["vs_budget_pct"] as? Int) ?? 0
        let projected = (pattern?["amount_projected_monthly"] as? Int) ?? 0

        let pron = formal ? "dumneavoastră" : "tale"
        if amount > 0 && vsBudgetPct > 0 {
            return "\(name), \(category) — \(amount) RON observate, +\(vsBudgetPct)% peste media \(pron) lunară. La ritmul ăsta, \(projected) RON până la sfârșitul lunii."
        }
        if amount > 0 {
            return "\(name), \(category): \(amount) RON în perioada observată. Solomon urmărește tiparul."
        }
        return "\(name), Solomon a observat un tipar nou la \(category)."
    }

    // MARK: - Subscription Audit

    private func renderSubscriptionAudit(_ ctx: [String: Any], name: String, formal: Bool) -> String {
        // SubscriptionAuditTotals are monthlyRecoverable + annualRecoverable + contextComparison
        let totals = ctx["totals"] as? [String: Any]
        let monthlyRecover = (totals?["monthly_recoverable"] as? Int) ?? 0
        let annualRecover = (totals?["annual_recoverable"] as? Int) ?? 0
        // ghost_subscriptions e array [{name, amount_monthly, ...}]
        let ghosts = ctx["ghost_subscriptions"] as? [[String: Any]] ?? []
        // Fallback: dacă totals lipsesc, calculăm din ghost items
        let savings = monthlyRecover > 0
            ? monthlyRecover
            : ghosts.reduce(0) { $0 + ((($1["amount_monthly"]) as? Int) ?? 0) }
        let savingsAnnual = annualRecover > 0 ? annualRecover : savings * 12

        let pron = formal ? "dumneavoastră" : "tale"
        let verb = formal ? "Anulați-le" : "Anulează-le"
        if ghosts.isEmpty {
            return "\(name), abonamentele \(pron) sunt în regulă — toate folosite recent."
        }
        let plural = ghosts.count == 1 ? "abonament fantomă" : "abonamente fantomă"
        let consum = formal ? "vă consumă" : "îți consumă"
        return "\(name), \(ghosts.count) \(plural) \(consum) \(savings) RON/lună. \(verb) și economisiți \(savingsAnnual) RON pe an."
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
        let diffPct = (spending?["diff_pct"] as? Int) ?? 0
        // SmallWin are exists + description (nu text)
        let smallWin = ctx["small_win"] as? [String: Any]
        let winExists = (smallWin?["exists"] as? Bool) ?? false
        let winText = smallWin?["description"] as? String

        let verb = formal ? "ați cheltuit" : "ai cheltuit"
        var msg = "\(name), săptămâna asta \(verb) \(total) RON."
        if diffPct != 0 {
            let dir = diffPct > 0 ? "peste" : "sub"
            msg += " Asta e \(abs(diffPct))% \(dir) media săptămânală."
        }
        if winExists, let w = winText, !w.isEmpty {
            msg += " 🎉 \(w)"
        }
        return msg
    }

    // MARK: - Helpers

    /// Traduce raw verdict reason (snake_case enum) în RO natural.
    private func translateVerdictReason(_ raw: String) -> String {
        switch raw {
        case "comfortable_margin":     return "ai marjă confortabilă"
        case "tight_but_workable":     return "e strâns dar se poate"
        case "would_create_overdraft": return "ai intra pe minus"
        case "would_break_obligation": return "ar pune în pericol o plată obligatorie"
        case "category_already_over":  return "ai depășit deja media la categoria asta"
        default:
            return raw.isEmpty ? "ar afecta obligațiile" : raw.replacingOccurrences(of: "_", with: " ")
        }
    }

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
