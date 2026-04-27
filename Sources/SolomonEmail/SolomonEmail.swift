import Foundation
import SolomonCore
import SolomonStorage

/// Namespace marker pentru modulul `SolomonEmail`.
///
/// Modulul expune pipeline-ul de parsare email → tranzacție:
/// - `EmailMessage`              — input brut (from, subject, body, date)
/// - `AmountExtractor`           — regex RON/EUR din text
/// - `SubjectClassifier`         — relevanță financiară + direcție din subiect
/// - `SenderMapper`              — match sender pe whitelist (~80 senders)
/// - `EmailTransactionParser`    — pipeline complet, produce `ParsedEmailTransaction`
/// - `ParsedEmailTransaction`    — rezultat cu confidence score și `.toTransaction()`
///
/// **Privacy by design:** emailul original NU se stochează —
/// doar `ParsedEmailTransaction` (fără body/from complet) este persistat.
public enum SolomonEmail {
    public static let moduleVersion = "1.0.0"
}
