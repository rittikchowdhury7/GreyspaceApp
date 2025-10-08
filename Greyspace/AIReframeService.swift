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
        let language = Localization.currentLanguage()
        switch self {
        case .emptyThought:
            return Localization.string("error.ai.emptyThought", fallback: "Thought input is empty.", language: language)
        case .missingAPIKey:
            return Localization.string("error.ai.missingKey", fallback: "Missing API key.", language: language)
        case .badHTTPStatus(let code):
            let format = Localization.string("error.ai.status", fallback: "Server returned status %d.", language: language)
            return String(format: format, code)
        case .badResponse:
            return Localization.string("error.ai.badResponse", fallback: "Invalid response from server.", language: language)
        case .decodingFailed:
            return Localization.string("error.ai.decoding", fallback: "Could not decode AI response.", language: language)
        }
    }
}

// MARK: - Service
/// Key-optional AI service. Works offline via local heuristics; uses OpenAI if key available.
struct AIReframeService {
    /// Provide your API key via this closure. If it returns nil/empty, local fallback is used.
    var apiKeyProvider: () -> String?
    var languageCodeProvider: () -> String

    /// OpenAI model names that support the **Responses** API (JSON control).
    var model: String = "gpt-4o-mini"
    var requestTimeout: TimeInterval = 15

    /// Default initializer: read OPENAI_API_KEY from Info.plist (optional).
    init(apiKeyProvider: @escaping () -> String? = {
        (Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String)
    }, languageCodeProvider: @escaping () -> String = {
        UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.defaultCode
    }) {
        self.apiKeyProvider = apiKeyProvider
        self.languageCodeProvider = languageCodeProvider
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
        let language = AppLanguage.resolved(for: languageCodeProvider())
        let hasKey = (apiKeyProvider()?.trimmed.isEmpty == false)
        print("AIReframeService will use \(hasKey ? "API" : "LOCAL") path")
        guard !t.isEmpty else { throw AIReframeError.emptyThought }

        // 1) Try OpenAI if key present
        if let key = apiKeyProvider()?.trimmed, !key.isEmpty {
            do {
                let fromAPI = try await reframeFromAPI(thought: t,
                                                      feeling: feeling,
                                                      why: why,
                                                      limit: limit,
                                                      language: language,
                                                      apiKey: key)
                if !fromAPI.isEmpty { return fromAPI }
            } catch {
                // fall through to local
            }
        }

        // 2) Local fallback (always)
        return LocalReframeEngine.propose(thought: t,
                                          feeling: feeling,
                                          why: why,
                                          limit: limit,
                                          language: language)
    }

    /// “Why did this thought show up?” suggestions. Works offline; uses API if available.
    @MainActor
    func whySuggestions(for thought: String,
                        feeling: String? = nil,
                        limit: Int = 8) async -> [String] {
        let language = AppLanguage.resolved(for: languageCodeProvider())
        // 1) Try API (if key)
        if let key = apiKeyProvider()?.trimmed, !key.isEmpty {
            do {
                let arr = try await whyFromAPI(thought: thought.trimmed,
                                               feeling: feeling?.trimmed,
                                               language: language,
                                               apiKey: key,
                                               limit: limit)
                if !arr.isEmpty { return Array(arr.prefix(limit)) }
            } catch {
                // fall back
            }
        }
        // 2) Local
        return Array(LocalWhyEngine.suggest(thought: thought,
                                            feeling: feeling,
                                            language: language).prefix(limit))
    }
}

// MARK: - Local Heuristics (fast, no network)
private enum LocalReframeEngine {
    static func propose(thought: String,
                        feeling: String?,
                        why: String?,
                        limit: Int,
                        language: AppLanguage) -> [String] {
        var out: [String] = [
            Localization.string("local.reframe.base.signal", fallback: "This urge is a signal, not my identity. I can choose a kinder action.", language: language),
            Localization.string("local.reframe.base.honest", fallback: "I can be honest about how I feel without judging myself.", language: language),
            Localization.string("local.reframe.base.progress", fallback: "I’m allowed to be a work in progress and still be worthy.", language: language),
            Localization.string("local.reframe.base.space", fallback: "I can make space for this feeling and then take one small helpful step.", language: language),
            Localization.string("local.reframe.base.connection", fallback: "I can seek connection directly instead of through this old pattern.", language: language)
        ]

        let t = thought.lowercased()
        let f = (feeling ?? "").lowercased()
        let w = (why ?? "").lowercased()

        if f.contains("anxiety") || f.contains("stress") || t.contains("nervous") {
            out.append(Localization.string("local.reframe.add.stress", fallback: "I’m stressed; a pause helps me say what I actually need.", language: language))
        }
        if f.contains("anger") || t.contains("angry") || t.contains("mad") {
            out.append(Localization.string("local.reframe.add.anger", fallback: "My anger wants release; I can cool off and speak clearly later.", language: language))
        }
        if f.contains("sad") || f.contains("lonely") || t.contains("alone") {
            out.append(Localization.string("local.reframe.add.lonely", fallback: "I’m craving support; I can ask for connection directly.", language: language))
        }
        if w.contains("accept") || w.contains("fit") || w.contains("belong") {
            out.append(Localization.string("local.reframe.add.belong", fallback: "I want to belong; I can build closeness by being genuine.", language: language))
        }
        if w.contains("judge") || w.contains("perfection") || t.contains("perfect") || t.contains("fail") {
            out.append(Localization.string("local.reframe.add.perfect", fallback: "I don’t have to be perfect to be acceptable.", language: language))
        }
        if w.contains("protect") || w.contains("safety") || w.contains("defend") {
            out.append(Localization.string("local.reframe.add.protect", fallback: "I’m trying to stay safe; I can choose protection that doesn’t hurt me or others.", language: language))
        }
        if w.contains("guilt") || t.contains("should") {
            out.append(Localization.string("local.reframe.add.guilt", fallback: "I can care for others without abandoning myself.", language: language))
        }
        if w.contains("control") || t.contains("control") {
            out.append(Localization.string("local.reframe.add.control", fallback: "I can focus on what I influence and let the rest be uncertain.", language: language))
        }

        return dedup(out, cap: limit)
    }
}

private enum LocalWhyEngine {
    static func suggest(thought: String, feeling: String?, language: AppLanguage) -> [String] {
        var base: [String] = [
            Localization.string("local.why.base.judgment", fallback: "Fear of judgment", language: language),
            Localization.string("local.why.base.control", fallback: "Wanting control", language: language),
            Localization.string("local.why.base.acceptance", fallback: "Seeking acceptance/belonging", language: language),
            Localization.string("local.why.base.protect", fallback: "Protecting myself from being hurt", language: language),
            Localization.string("local.why.base.guilt", fallback: "Feeling guilty or responsible", language: language),
            Localization.string("local.why.base.comfort", fallback: "Seeking comfort or relief", language: language),
            Localization.string("local.why.base.overwhelm", fallback: "Feeling overwhelmed or burned out", language: language),
            Localization.string("local.why.base.uncertainty", fallback: "Uncertainty or fear of the unknown", language: language),
            Localization.string("local.why.base.compare", fallback: "Comparing myself to others", language: language),
            Localization.string("local.why.base.habit", fallback: "Old habit that used to help", language: language)
        ]

        let t = thought.lowercased()
        let f = (feeling ?? "").lowercased()

        if t.contains("perfect") || t.contains("fail") || f.contains("anxiety") || f.contains("stress") {
            base.append(contentsOf: [
                Localization.string("local.why.add.perfection", fallback: "Perfectionism / fear of mistakes", language: language),
                Localization.string("local.why.add.catastrophizing", fallback: "Catastrophizing outcomes", language: language)
            ])
        }
        if t.contains("alone") || t.contains("left out") || f.contains("lonely") {
            base.append(Localization.string("local.why.add.abandoned", fallback: "Fear of being left out or abandoned", language: language))
        }
        if t.contains("family") || t.contains("parents") {
            base.append(contentsOf: [
                Localization.string("local.why.add.familyExpectations", fallback: "Navigating family expectations", language: language),
                Localization.string("local.why.add.keepPeace", fallback: "Trying to keep the peace at home", language: language)
            ])
        }
        if t.contains("work") || t.contains("school") {
            base.append(Localization.string("local.why.add.perform", fallback: "Pressure to perform at work/school", language: language))
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
                                language: AppLanguage,
                                apiKey: String) async throws -> [String] {

        let languageInstruction: String
        if language.code == "system" {
            languageInstruction = "Match the user’s language. If unsure, respond in English."
        } else {
            let code = language.localeIdentifier ?? "en"
            languageInstruction = "Respond in \(language.englishName) (language code: \(code))."
        }

        let sys = """
        You help users write balanced, compassionate reframes of sticky thoughts.
        Return ONLY compact JSON: {"reframes":["...", "..."]}.
        Rules: 1–2 short sentences each, plain language, no clinical advice or diagnoses.
        Avoid toxic positivity; be realistic and validating.
        \(languageInstruction)
        """

        let user = """
        Thought: "\(thought)"
        Feeling: "\(feeling ?? "")"
        Why it showed up (user’s guess): "\(why ?? "")"
        Generate \(max(3, min(7, limit))) distinct, broadly applicable reframes.
        Preferred language: \(language.englishName)
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
                            language: AppLanguage,
                            apiKey: String,
                            limit: Int) async throws -> [String] {

        let languageInstruction: String
        if language.code == "system" {
            languageInstruction = "Match the user’s language. If unsure, respond in English."
        } else {
            let code = language.localeIdentifier ?? "en"
            languageInstruction = "Respond in \(language.englishName) (language code: \(code))."
        }

        let sys = """
        You help users explore why a difficult thought might show up.
        Return ONLY a compact json object exactly like: {"suggestions":["...", "..."]}.
        No clinical jargon; <= 7 words each.
        \(languageInstruction)
        """

        let user = """
        Thought: "\(thought)"
        Feeling (optional): "\(feeling ?? "")"
        Provide \(max(6, min(10, limit))) broad, non-clinical reasons.
        Preferred language: \(language.englishName)
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
