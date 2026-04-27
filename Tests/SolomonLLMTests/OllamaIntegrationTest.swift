import Testing
import Foundation
@testable import SolomonLLM

/// Teste de integrare cu Ollama real — SKIP automat dacă Ollama nu e disponibil.
///
/// Rulează manual cu: `swift test --filter OllamaIntegrationTests`
/// Necesită: `ollama serve` + model `gemma4:e2b` descărcat.
///
/// Cu `think:false` activat, răspunsurile vin în < 30s după încărcarea modelului.
/// Timeout per test: 2 minute (acoperă și first-load ~60s).
@Suite(.serialized) struct OllamaIntegrationTests {

    /// Verifică dacă Ollama e disponibil la adresa default.
    static func ollamaIsAvailable() async -> Bool {
        guard let url = URL(string: "http://localhost:11434/api/version") else { return false }
        var req = URLRequest(url: url, timeoutInterval: 3)
        req.httpMethod = "GET"
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    @Test(.timeLimit(.minutes(3))) func canIAffordPromptInRomanian() async throws {
        guard await Self.ollamaIsAvailable() else {
            print("⚠️  Ollama nu e disponibil — test sărit.")
            return
        }

        let provider = OllamaLLMProvider(
            model: "gemma4:e2b",
            temperature: 0.3,
            timeoutSeconds: 120
        )

        let systemPrompt = """
        Ești Solomon, asistentul financiar personal. \
        Verdictul e pre-calculat: utilizatorul ÎȘI POATE PERMITE. \
        Răspunde direct în română, max 40 cuvinte, ton cald.
        """

        let context = """
        {"moment_type":"can_i_afford","user":{"name":"Andrei","addressing":"tu"},
         "decision":{"verdict":"yes","math_visible":"după pizza: 735 RON / 9 zile = 81 RON/zi"},
         "query":{"amount_requested":65,"raw_text":"pizza de la Glovo"}}
        """

        let response = try await provider.generate(
            systemPrompt: systemPrompt,
            userContext: context,
            maxWords: 40
        )

        print("\n🤖 RĂSPUNS GEMMA4 (CanIAfford):\n\(response)\n")

        #expect(!response.isEmpty)
        // Verificăm că răspunsul e în română (conține diacritice sau cuvinte românești comune)
        let romanianIndicators = ["ți", "și", "că", "în", "ai", "da", "nu", "poți", "după", "RON"]
        let hasRomanian = romanianIndicators.contains { response.lowercased().contains($0) }
        #expect(hasRomanian, "Răspunsul trebuie să fie în română: \(response)")
    }

    @Test(.timeLimit(.minutes(3))) func paydayPromptInRomanian() async throws {
        guard await Self.ollamaIsAvailable() else {
            print("⚠️  Ollama nu e disponibil — test sărit.")
            return
        }

        let provider = OllamaLLMProvider(temperature: 0.4, timeoutSeconds: 120)

        let systemPrompt = """
        Ești Solomon. Salariul tocmai a intrat. \
        Prezintă pe scurt alocarea: obligații rezervate, suma disponibilă, suma pe zi. \
        Tonul vesel. Max 50 cuvinte în română.
        """

        let context = """
        {"moment_type":"payday","user":{"name":"Andrei","addressing":"tu"},
         "salary":{"amount_received":5200,"is_higher_than_average":true},
         "auto_allocation":{"obligations_total":1500,"available_to_spend":3660,"available_per_day":122}}
        """

        let response = try await provider.generate(
            systemPrompt: systemPrompt,
            userContext: context,
            maxWords: 50
        )

        print("\n🤖 RĂSPUNS GEMMA4 (Payday):\n\(response)\n")

        #expect(!response.isEmpty)
    }

    @Test(.timeLimit(.minutes(3))) func spiralAlertPromptInRomanian() async throws {
        guard await Self.ollamaIsAvailable() else {
            print("⚠️  Ollama nu e disponibil — test sărit.")
            return
        }

        let provider = OllamaLLMProvider(temperature: 0.3, timeoutSeconds: 120)

        let systemPrompt = """
        Ești Solomon. Detectezi stres financiar. \
        Prezintă situația cu empatie și primul pas concret din planul de recuperare. \
        Tonul cald, orientat spre soluții. Max 60 cuvinte în română.
        """

        let context = """
        {"moment_type":"spiral_alert","user":{"name":"Andrei","addressing":"tu"},
         "spiral_score":3,"severity":"high",
         "narrative_summary":"Soldul scade constant cu 15% pe lună.",
         "recovery_plan":{"step1":{"action":"Anulează HBO Max și Spotify (62 RON/lună)","complexity":"easy"}}}
        """

        let response = try await provider.generate(
            systemPrompt: systemPrompt,
            userContext: context,
            maxWords: 60
        )

        print("\n🤖 RĂSPUNS GEMMA4 (SpiralAlert):\n\(response)\n")

        #expect(!response.isEmpty)
    }
}
