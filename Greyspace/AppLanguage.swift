import SwiftUI

struct AppLanguage: Identifiable, Hashable {
    static let storageKey = "AppLanguage"
    static let defaultCode = "system"

    let code: String
    let localeIdentifier: String?
    let nameKey: String
    let englishName: String

    var id: String { code }
    var localizedKey: LocalizedStringKey { LocalizedStringKey(nameKey) }

    static let all: [AppLanguage] = [
        AppLanguage(code: "system", localeIdentifier: nil, nameKey: "language.display.system", englishName: "System"),
        AppLanguage(code: "en", localeIdentifier: "en", nameKey: "language.display.english", englishName: "English"),
        AppLanguage(code: "hi", localeIdentifier: "hi", nameKey: "language.display.hindi", englishName: "Hindi"),
        AppLanguage(code: "fil", localeIdentifier: "fil", nameKey: "language.display.tagalog", englishName: "Tagalog"),
        AppLanguage(code: "zh-Hans", localeIdentifier: "zh-Hans", nameKey: "language.display.chinese", englishName: "Chinese (Simplified)")
    ]

    static func resolved(for rawCode: String?) -> AppLanguage {
        let code = rawCode ?? defaultCode
        return all.first { $0.code == code } ?? all[1]
    }

    static func locale(for code: String) -> Locale {
        let lang = resolved(for: code)
        if let identifier = lang.localeIdentifier {
            return Locale(identifier: identifier)
        }
        return Locale.autoupdatingCurrent
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        guard language.code != "system", let identifier = language.localeIdentifier,
              let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    static func bundle(forCode code: String) -> Bundle {
        bundle(for: resolved(for: code))
    }

    static func applySelection(_ code: String) {
        let resolved = resolved(for: code)
        let defaults = UserDefaults.standard
        let stored = defaults.string(forKey: storageKey)
        if stored != resolved.code {
            defaults.set(resolved.code, forKey: storageKey)
        }
        defaults.synchronize()
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("AppLanguageDidChange")
}
