import Foundation

enum NetworkError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case emptyAnswer

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Nieprawidłowa odpowiedź serwera"
        case .apiError(let msg): return "API: \(msg)"
        case .emptyAnswer: return "Pusta odpowiedź z modelu"
        }
    }
}

final class NetworkManager {
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let model = "anthropic/claude-sonnet-4.6"

    private let systemPrompt = """
        Przeanalizuj obraz z pytaniem testowym. Uwaga: mogą to być pytania jedno- lub wielokrotnego wyboru. \
        Zwróć TYLKO numer poprawnej odpowiedzi (np. '2') lub numery oddzielone przecinkiem, jeśli jest ich więcej \
        (np. '1, 3, 4'). Absolutnie nie dodawaj żadnego innego tekstu, wstępu ani wyjaśnień.
        """

    func analyzeImage(imageData: Data) async throws -> String {
        let apiKey = APIConfig.openRouterKey
        guard !apiKey.isEmpty else {
            throw NetworkError.apiError("Brak klucza API — ustaw OPENROUTER_API_KEY lub edytuj APIConfig.swift")
        }

        let base64 = imageData.base64EncodedString()
        let dataURI = "data:image/png;base64,\(base64)"

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": ["url": dataURI]
                        ],
                        [
                            "type": "text",
                            "text": "Jaka jest poprawna odpowiedź?"
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw NetworkError.apiError("HTTP \(httpResponse.statusCode): \(body)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NetworkError.invalidResponse
        }

        let answer = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            throw NetworkError.emptyAnswer
        }

        return answer
    }
}
