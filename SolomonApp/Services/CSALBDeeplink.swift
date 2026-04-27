import Foundation
import UIKit

// MARK: - CSALBDeeplink
//
// Helper pentru deschiderea CSALB (Centrul de Soluționare Alternativă a Litigiilor
// Bancare) — folosit pentru cazuri severe de spirală IFN/credit.
// CSALB e gratuit pentru consumatori și mediază cu băncile/IFN-urile.
//
// URL: https://www.csalb.ro/incepe-procedura

@MainActor
public enum CSALBDeeplink {

    public static let mainURL = URL(string: "https://www.csalb.ro")!
    public static let startProcedureURL = URL(string: "https://www.csalb.ro/incepe-procedura")!
    public static let infoURL = URL(string: "https://www.csalb.ro/despre-csalb")!

    /// Deschide pagina de start procedură mediere.
    /// Apelat când Solomon detectează spirală cu severitate critică.
    public static func openStartProcedure() {
        UIApplication.shared.open(startProcedureURL)
    }

    public static func openMainSite() {
        UIApplication.shared.open(mainURL)
    }
}
