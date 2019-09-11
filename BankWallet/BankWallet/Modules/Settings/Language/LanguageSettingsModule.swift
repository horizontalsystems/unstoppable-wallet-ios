protocol ILanguageSettingsView: class {
    func show(viewItems: [LanguageViewItem])
}

protocol ILanguageSettingsViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol ILanguageSettingsInteractor: AnyObject {
    var currentLanguage: String { get set }
    var availableLanguages: [String] { get }
    func displayName(language: String) -> String?
    func nativeDisplayName(language: String) -> String?
}

protocol ILanguageSettingsRouter {
    func dismiss()
    func reloadAppInterface()
}

struct LanguageViewItem {
    let language: String
    let name: String?
    let nativeName: String?
    let selected: Bool
}
