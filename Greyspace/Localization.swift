import Foundation

enum Localization {
    static func currentLanguage() -> AppLanguage {
        let code = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.defaultCode
        return AppLanguage.resolved(for: code)
    }

    static func string(_ key: String, fallback: String, language: AppLanguage? = nil) -> String {
        let lang = language ?? currentLanguage()
        let bundle = AppLanguage.bundle(for: lang)
        let value = bundle.localizedString(forKey: key, value: fallback, table: nil)
        return value.isEmpty ? fallback : value
    }
}
