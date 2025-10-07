//
//  AIReframeService.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

import Foundation

// MARK: - Public Protocol (used by ThoughtBuilder)
protocol ReframeSuggester2 {
    func suggest(for thought: String, feeling: String, why: String) async throws -> [String]
}

// MARK: - Errors
enum AIReframeError: LocalizedError {
    case emptyThought
    case missingAPIKey
    case badHTTPStatus(Int)
    case badResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .emptyThought:   return "Thought input is empty."
        case .missingAPIKey:  return "Missing API key."
        case .badHTTPStatus(let code): return "Server returned status \(code)."
        case .badResponse:    return "Invalid response from server."
        case .decodingFailed: return "Could not decode AI response."
        }
    }
}

// MARK: - Service
/// Key-optional AI service. Works offline via local heuristics; uses OpenAI if key available.
struct AIReframeService {
    /// Provide your API key via this closure. If it returns nil/empty, local fallback is used.
    var apiKeyProvider: () -> String?

    /// OpenAI model names that support the **Responses** API (JSON control).
    var model: String = "gpt-4o-mini"
    var requestTimeout: TimeInterval = 15

    /// Default initializer: read OPENAI_API_KEY from Info.plist (optional).
    init(apiKeyProvider: @escaping () -> String? = {
        (Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String)
    }) {
        self.apiKeyProvider = apiKeyProvider
    }
}

// MARK: - ReframeSuggester conformance (used by ThoughtBuilder “More ideas”)
extension AIReframeService: ReframeSuggester2 {
    /// Main entry used by the UI “More ideas” button.
    func suggest(for thought: String, feeling: String, why: String) async throws -> [String] {
        try await suggestReframes(thought: thought, feeling: feeling.nilIfBlank, why: why.nilIfBlank, limit: 5)
    }
}

// MARK: - Public API
extension AIReframeService {

    /// Get reframing suggestions. Falls back to local if no API key or any network error.
    func suggestReframes(thought: String,
                         feeling: String? = nil,
                         why: String? = nil,
                         limit: Int = 5) async throws -> [String] {
        let t = thought.trimmed
        let hasKey = (apiKeyProvider()?.trimmed.isEmpty == false)
        print("AIReframeService will use \(hasKey ? "API" : "LOCAL") path")
        guard !t.isEmpty else { throw AIReframeError.emptyThought }

        // 1) Try OpenAI if key present
        if let key = apiKeyProvider()?.trimmed, !key.isEmpty {
            do {
                let fromAPI = try await reframeFromAPI(thought: t, feeling: feeling, why: why, limit: limit, apiKey: key)
                if !fromAPI.isEmpty { return fromAPI }
            } catch {
                // fall through to local
            }
        }

        // 2) Local fallback (always)
        return LocalReframeEngine.propose(thought: t, feeling: feeling, why: why, limit: limit)
    }

    /// “Why did this thought show up?” suggestions. Works offline; uses API if available.
    @MainActor
    func whySuggestions(for thought: String,
                        feeling: String? = nil,
                        limit: Int = 8) async -> [String] {
        // 1) Try API (if key)
        if let key = apiKeyProvider()?.trimmed, !key.isEmpty {
            do {
                let arr = try await whyFromAPI(thought: thought.trimmed, feeling: feeling?.trimmed, apiKey: key, limit: limit)
                if !arr.isEmpty { return Array(arr.prefix(limit)) }
            } catch {
                // fall back
            }
        }
        // 2) Local
        return Array(LocalWhyEngine.suggest(thought: thought, feeling: feeling).prefix(limit))
    }
}

// MARK: - Local Heuristics (fast, no network)
private enum LocalReframeEngine {
    static func propose(thought: String, feeling: String?, why: String?, limit: Int) -> [String] {
        var out: [String] = [
            "This urge is a signal, not my identity. I can choose a kinder action.",
            "I can be honest about how I feel without judging myself.",
            "I’m allowed to be a work in progress and still be worthy.",
            "I can make space for this feeling and then take one small helpful step.",
            "I can seek connection directly instead of through this old pattern."
        ]

        let t = thought.lowercased()
        let f = (feeling ?? "").lowercased()
        let w = (why ?? "").lowercased()

        if f.contains("anxiety") || f.contains("stress") || t.contains("nervous") {
            out.append("I’m stressed; a pause helps me say what I actually need.")
        }
        if f.contains("anger") || t.contains("angry") || t.contains("mad") {
            out.append("My anger wants release; I can cool off and speak clearly later.")
        }
        if f.contains("sad") || f.contains("lonely") || t.contains("alone") {
            out.append("I’m craving support; I can ask for connection directly.")
        }
        if w.contains("accept") || w.contains("fit") || w.contains("belong") {
            out.append("I want to belong; I can build closeness by being genuine.")
        }
        if w.contains("judge") || w.contains("perfection") || t.contains("perfect") || t.contains("fail") {
            out.append("I don’t have to be perfect to be acceptable.")
        }
        if w.contains("protect") || w.contains("safety") || w.contains("defend") {
            out.append("I’m trying to stay safe; I can choose protection that doesn’t hurt me or others.")
        }
        if w.contains("guilt") || t.contains("should") {
            out.append("I can care for others without abandoning myself.")
        }
        if w.contains("control") || t.contains("control") {
            out.append("I can focus on what I influence and let the rest be uncertain.")
        }

        return dedup(out, cap: limit)
    }
}

private enum LocalWhyEngine {
    static func suggest(thought: String, feeling: String?) -> [String] {
        var base: [String] = [
            "Fear of judgment",
            "Wanting control",
            "Seeking acceptance/belonging",
            "Protecting myself from being hurt",
            "Feeling guilty or responsible",
            "Seeking comfort or relief",
            "Feeling overwhelmed or burned out",
            "Uncertainty or fear of the unknown",
            "Comparing myself to others",
            "Old habit that used to help"
        ]

        let t = thought.lowercased()
        let f = (feeling ?? "").lowercased()

        if t.contains("perfect") || t.contains("fail") || f.contains("anxiety") || f.contains("stress") {
            base.append(contentsOf: ["Perfectionism / fear of mistakes", "Catastrophizing outcomes"])
        }
        if t.contains("alone") || t.contains("left out") || f.contains("lonely") {
            base.append("Fear of being left out or abandoned")
        }
        if t.contains("family") || t.contains("parents") {
            base.append(contentsOf: ["Navigating family expectations", "Trying to keep the peace at home"])
        }
        if t.contains("work") || t.contains("school") {
            base.append("Pressure to perform at work/school")
        }

        return dedup(base, cap: 20)
    }
}

// MARK: - OpenAI (Responses API) — optional
private extension AIReframeService {
    
    private func reframeFromAPI(thought: String,
                                feeling: String?,
                                why: String?,
                                limit: Int,
                                apiKey: String) async throws -> [String] {
        
        let sys = """
        You help users write balanced, compassionate reframes of sticky thoughts.
        Return ONLY compact JSON: {"reframes":["...", "..."]}.
        Rules: 1–2 short sentences each, plain language, no clinical advice or diagnoses.
        Avoid toxic positivity; be realistic and validating.
        """
        
        let user = """
        Thought: "\(thought)"
        Feeling: "\(feeling ?? "")"
        Why it showed up (user’s guess): "\(why ?? "")"
        Generate \(max(3, min(7, limit))) distinct, broadly applicable reframes.
        """
        let keyPreview = apiKeyProvider()?.prefix(6) ?? "nil"
        debugLog("Key present? ->", keyPreview, "…")
        
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.timeoutInterval = requestTimeout
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,                     // e.g. "gpt-4o-mini"
            "temperature": 0.4,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": sys],
                ["role": "user",   "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw AIReframeError.badResponse }
        debugLog("reframe status:", http.statusCode)
        if !(200..<300).contains(http.statusCode) {
            debugLog("reframe error body:", String(data: data, encoding: .utf8) ?? "<non-utf8>")
            throw AIReframeError.badHTTPStatus(http.statusCode)
        }
        
        struct ChoiceMsg: Decodable { let message: Msg }
        struct Msg: Decodable { let content: String }
        struct ChatResp: Decodable { let choices: [ChoiceMsg] }
        
        let decoded = try JSONDecoder().decode(ChatResp.self, from: data)
        let text = decoded.choices.first?.message.content ?? ""
        
        // Expect {"reframes":[...]}
        if let obj = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
           let arr = obj["reframes"] as? [String] {
            return dedup(arr, cap: limit)
        }
        
        // Fallback parsing if the model ignored JSON mode
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: #"^[\-\*\d\.\s]+"#, with: "", options: .regularExpression) }
        return dedup(lines, cap: limit)
    }
    
    // whyFromAPI (chat/completions)
    private func whyFromAPI(thought: String,
                            feeling: String?,
                            apiKey: String,
                            limit: Int) async throws -> [String] {
        
        let sys = """
        You help users explore why a difficult thought might show up.
        Return ONLY a compact json object exactly like: {"suggestions":["...", "..."]}.
        No clinical jargon; <= 7 words each.
        """
        
        let user = """
        Thought: "\(thought)"
        Feeling (optional): "\(feeling ?? "")"
        Provide \(max(6, min(10, limit))) broad, non-clinical reasons.
        """
        
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.timeoutInterval = requestTimeout
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": model,
            "temperature": 0.3,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": sys],
                ["role": "user",   "content": user]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw AIReframeError.badResponse }
        debugLog("why status:", http.statusCode)
        if !(200..<300).contains(http.statusCode) {
            debugLog("why error body:", String(data: data, encoding: .utf8) ?? "<non-utf8>")
            throw AIReframeError.badHTTPStatus(http.statusCode)
        }
        
        struct ChoiceMsg: Decodable { let message: Msg }
        struct Msg: Decodable { let content: String }
        struct ChatResp: Decodable { let choices: [ChoiceMsg] }
        
        let decoded = try JSONDecoder().decode(ChatResp.self, from: data)
        let text = decoded.choices.first?.message.content ?? ""
        
        if let obj = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
           let arr = obj["suggestions"] as? [String] {
            return dedup(arr, cap: limit)
        }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: #"^[\-\*\d\.\s]+"#, with: "", options: .regularExpression) }
        return dedup(lines, cap: limit)
    }
}
    
// MARK: - Utilities
private func dedup(_ array: [String], cap: Int) -> [String] {
    let cleaned = array
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty && $0.count <= 160 }
    var seen = Set<String>()
    let unique = cleaned.filter { seen.insert($0.lowercased()).inserted }
    return Array(unique.prefix(max(1, cap)))
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfBlank: String? { let s = trimmed; return s.isEmpty ? nil : s }
}

private func debugLog(_ items: Any...) {
    #if DEBUG
    print("[AIReframeService]", items.map { "\($0)" }.joined(separator: " "))
    #endif
}
