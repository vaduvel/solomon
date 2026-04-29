import Foundation
import SolomonCore

/// Parser principal — orchestrează `SenderMapper`, `SubjectClassifier` și
/// `AmountExtractor` pentru a produce un `ParsedEmailTransaction` din orice email.
///
/// Pipeline (spec §8.11):
/// 1. Sender match (whitelist) → merchant + categorie + confidence
/// 2. Subject keyword check → relevanță + direction hint
/// 3. Body amount extraction → suma tranzacției
/// 4. Compozit confidence score → decizie auto-import vs. review manual
public struct EmailTransactionParser: Sendable {

    let senderMapper    = SenderMapper()
    let subjectClassifier = SubjectClassifier()
    let amountExtractor = AmountExtractor()

    public init() {}

    // MARK: - Main entry point

    /// Parsează un email și returnează `nil` dacă emailul nu e financiar relevant.
    public func parse(_ email: EmailMessage) -> ParsedEmailTransaction? {
        // Pasul 1: sender lookup
        let senderResult = senderMapper.map(from: email.from)

        // Pasul 2: relevance check
        let isRelevantSubject = subjectClassifier.isFinanciallyRelevant(email.subject)
        let isRelevantBody    = bodyContainsAmountPattern(email.bodyText)

        // Reject rapid: sender necunoscut + nici subiect, nici body relevante
        if senderResult == nil && !isRelevantSubject && !isRelevantBody {
            return nil
        }

        // Pasul 3: extrage suma
        let amount = amountExtractor.extractTransactionAmount(from: email.bodyText)
            ?? amountExtractor.extractPrimary(from: email.subject)

        // Pasul 4: determină merchant, categorie, direcție
        let merchant  = senderResult?.sender.displayName
        let category  = resolveCategory(senderResult: senderResult, subject: email.subject)
        let direction = resolveDirection(senderResult: senderResult,
                                        subject: email.subject,
                                        category: category)

        // Pasul 5: scor confidență compozit
        let (confidence, confidenceSource) = computeConfidence(
            senderResult: senderResult,
            isRelevantSubject: isRelevantSubject,
            isRelevantBody: isRelevantBody,
            hasAmount: amount != nil
        )

        return ParsedEmailTransaction(
            from: email.from,
            subject: email.subject,
            date: email.date,
            amount: amount,
            merchant: merchant,
            suggestedCategory: category,
            direction: direction,
            confidence: confidence,
            confidenceSource: confidenceSource
        )
    }

    // MARK: - Helpers

    /// Quick check dacă body-ul conține un pattern de sumă (spec §8.11).
    private func bodyContainsAmountPattern(_ body: String) -> Bool {
        Self.quickAmountPattern.firstMatch(in: body, range: NSRange(body.startIndex..., in: body)) != nil
    }

    private static let quickAmountPattern: NSRegularExpression = {
        guard let re = try? NSRegularExpression(
            pattern: #"\d+[,.]?\d*\s*(RON|lei|EUR|€)"#,
            options: .caseInsensitive
        ) else { preconditionFailure("EmailTransactionParser.quickAmountPattern: invalid pattern") }
        return re
    }()

    private func resolveCategory(
        senderResult: SenderMatchResult?,
        subject: String
    ) -> TransactionCategory {
        // Categoria din sender registry are prioritate
        if let sr = senderResult, sr.sender.defaultTransactionCategory != .unknown {
            return sr.sender.defaultTransactionCategory
        }
        // Fallback: hint din subject
        if let hint = subjectClassifier.suggestCategory(subject) {
            return hint
        }
        return .unknown
    }

    private func resolveDirection(
        senderResult: SenderMatchResult?,
        subject: String,
        category: TransactionCategory
    ) -> FlowDirection {
        // IFN incoming email = credit primit (incoming) — excepție!
        if let sr = senderResult, sr.sender.category == .ifn {
            // Dacă subject conține "credit" sau "aprobare" → incoming
            let s = subject.lowercased()
            if s.contains("credit") || s.contains("aprobare") || s.contains("virat") {
                return .incoming
            }
        }

        // Subject direction hint
        if let subjectDir = subjectClassifier.inferDirection(subject) {
            return subjectDir
        }

        // Categoria de datorii (BNPL plata) → outgoing
        if category == .bnpl || category == .loansIFN || category == .loansBank {
            return .outgoing
        }

        // Default: cheltuielile sunt outgoing
        return .outgoing
    }

    private func computeConfidence(
        senderResult: SenderMatchResult?,
        isRelevantSubject: Bool,
        isRelevantBody: Bool,
        hasAmount: Bool
    ) -> (confidence: Double, source: ConfidenceSource) {

        var base: Double
        var source: ConfidenceSource

        if let sr = senderResult {
            base = sr.confidenceScore
            source = sr.confidence == .exact ? .senderExactMatch : .senderDomainMatch
        } else if isRelevantSubject || isRelevantBody {
            base = 0.35
            source = .keywordMatch
        } else {
            return (0.0, .noMatch)
        }

        // Bonus: subiect relevant
        if isRelevantSubject { base = min(1.0, base + 0.05) }
        // Bonus: body conține sumă
        if isRelevantBody { base = min(1.0, base + 0.03) }
        // Penalizare: lipsă sumă extrasă
        if !hasAmount { base = max(0.0, base - 0.20) }

        return (base, source)
    }
}
