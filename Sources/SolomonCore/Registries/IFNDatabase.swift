import Foundation

/// Categoria de risc a unui IFN — folosită de Spiral Detector și apărarea proactivă.
public enum IFNRiskTier: String, Sendable, Hashable, Codable {
    /// DAE până la ~250% — risc moderat, dar peste credit bancar standard.
    case high
    /// DAE 250%–1000% — risc mare, semnal puternic de spirală.
    case veryHigh = "very_high"
    /// DAE peste 1000% — toxic, cere alertă imediată + CSALB Bridge.
    case extreme
}

/// Înregistrare pentru un IFN cunoscut (spec §10.1).
public struct IFNRecord: Sendable, Hashable, Codable, Identifiable {
    public var id: String { domain }
    public var name: String
    public var domain: String
    public var emailSenderPattern: String
    public var daeMinPercent: Int
    public var daeMaxPercent: Int
    public var typicalLoanRange: ClosedRange<Int>
    public var riskTier: IFNRiskTier

    public init(name: String, domain: String, emailSenderPattern: String,
                daeMinPercent: Int, daeMaxPercent: Int,
                typicalLoanRange: ClosedRange<Int>, riskTier: IFNRiskTier) {
        self.name = name
        self.domain = domain
        self.emailSenderPattern = emailSenderPattern
        self.daeMinPercent = daeMinPercent
        self.daeMaxPercent = daeMaxPercent
        self.typicalLoanRange = typicalLoanRange
        self.riskTier = riskTier
    }

    /// Estimează costul total de rambursare pentru un împrumut, ca multiplicator
    /// față de suma împrumutată — folosit de moment-ul IFN Incoming (§10.1).
    public func estimatedRepaymentMultiplier(termMonths: Int = 6) -> Double {
        // DAE (%) × ani × (1 + DAE/2 ca aproximare grossă pentru dobândă efectivă)
        let years = Double(termMonths) / 12.0
        let dae = Double(daeMinPercent) / 100.0
        return 1.0 + dae * years
    }
}

/// Catalogul IFN-urilor active pe piața RO + DAE-urile lor (spec §8.6 + §10.1).
///
/// Sursele de date:
/// - SOLOMON-V1-MASTER-SPEC.md §10.1 (DAE typical)
/// - SOLOMON-V1-MASTER-SPEC.md §8.6 (sender domains)
/// - Date publice ANPC / ASF (verificate manual la actualizare)
public enum IFNDatabase {

    public static let all: [IFNRecord] = [
        IFNRecord(
            name: "Credius",
            domain: "credius.ro",
            emailSenderPattern: "no-reply@credius.ro",
            daeMinPercent: 280, daeMaxPercent: 2_334,
            typicalLoanRange: 300...3_000,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "Provident",
            domain: "providentromania.ro",
            emailSenderPattern: "office@providentromania.ro",
            daeMinPercent: 100, daeMaxPercent: 650,
            typicalLoanRange: 500...8_000,
            riskTier: .veryHigh
        ),
        IFNRecord(
            name: "IUTE Credit",
            domain: "iutecredit.ro",
            emailSenderPattern: "no-reply@iutecredit.ro",
            daeMinPercent: 250, daeMaxPercent: 1_800,
            typicalLoanRange: 200...5_000,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "Viva Credit",
            domain: "vivacredit.ro",
            emailSenderPattern: "contact@vivacredit.ro",
            daeMinPercent: 200, daeMaxPercent: 1_500,
            typicalLoanRange: 200...4_000,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "Hora Credit",
            domain: "horacredit.ro",
            emailSenderPattern: "contact@horacredit.ro",
            daeMinPercent: 150, daeMaxPercent: 1_200,
            typicalLoanRange: 200...3_500,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "MaiMai Credit",
            domain: "maimaicredit.ro",
            emailSenderPattern: "suport@maimaicredit.ro",
            daeMinPercent: 200, daeMaxPercent: 2_490,
            typicalLoanRange: 200...4_000,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "Acredit",
            domain: "acredit.ro",
            emailSenderPattern: "contact@acredit.ro",
            daeMinPercent: 280, daeMaxPercent: 2_334,
            typicalLoanRange: 200...3_000,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "Ferratum",
            domain: "ferratum.ro",
            emailSenderPattern: "support@ferratum.ro",
            daeMinPercent: 200, daeMaxPercent: 1_500,
            typicalLoanRange: 200...4_000,
            riskTier: .extreme
        ),
        IFNRecord(
            name: "Cetelem",
            domain: "cetelem.ro",
            emailSenderPattern: "support@cetelem.ro",
            daeMinPercent: 12, daeMaxPercent: 35,
            typicalLoanRange: 1_000...50_000,
            riskTier: .high   // Cetelem e consumer credit „soft", nu IFN clasic.
        )
    ]

    /// Caută un IFN după domeniu (e-mail sender domain match).
    public static func record(forDomain domain: String) -> IFNRecord? {
        let normalized = domain.lowercased()
        return all.first { $0.domain == normalized }
    }

    /// Caută un IFN după sender e-mail (match exact).
    public static func record(forSender sender: String) -> IFNRecord? {
        let normalized = sender.lowercased()
        return all.first { $0.emailSenderPattern.lowercased() == normalized }
    }

    /// Toate IFN-urile cu risk tier dat sau mai mare.
    public static func atLeast(_ tier: IFNRiskTier) -> [IFNRecord] {
        let order: [IFNRiskTier: Int] = [.high: 0, .veryHigh: 1, .extreme: 2]
        let threshold = order[tier] ?? 0
        return all.filter { (order[$0.riskTier] ?? 0) >= threshold }
    }
}
