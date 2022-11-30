import HdWalletKit

extension Mnemonic.Language {

    var language: String {
        switch self {
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .spanish: return "es"
        case .simplifiedChinese: return "zh-Hans"
        case .traditionalChinese: return "zh-Hant"
        case .french: return "fr"
        case .italian: return "it"
        case .czech: return "cs"
        case .portuguese: return "pt"
        }
    }

}
