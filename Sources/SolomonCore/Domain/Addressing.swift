import Foundation

/// Modul în care Solomon i se adresează utilizatorului (spec §11 ecran 2).
public enum Addressing: String, Codable, Sendable, Hashable, CaseIterable {
    /// Familiar — „tu", verbe la persoana a 2-a singular.
    case tu = "tu"
    /// Formal — „dumneavoastră", verbe la persoana a 2-a plural.
    case dumneavoastra = "dumneavoastra"

    /// Pronume personal (subiect/obiect) pentru construcție de fraze.
    public var subjectPronoun: String {
        switch self {
        case .tu:             return "tu"
        case .dumneavoastra:  return "dumneavoastră"
        }
    }

    /// Forma verbului „a putea" la prezent persoana 2 (DA / NU response).
    public var canVerb: String {
        switch self {
        case .tu:             return "poți"
        case .dumneavoastra:  return "puteți"
        }
    }

    /// Marker pentru verbele la imperativ (folosit de prompt builder).
    public var imperativeSuffix: String {
        switch self {
        case .tu:             return "tu_form"
        case .dumneavoastra:  return "formal"
        }
    }
}
