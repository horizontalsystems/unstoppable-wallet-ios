struct LanguageItem: Equatable {
    let id: String
    let title: String
    let subtitle: String
    let current: Bool

    static func ==(lhs: LanguageItem, rhs: LanguageItem) -> Bool {
        return lhs.id == rhs.id
    }
}

protocol ILanguageSettingsView: class {
    func set(title: String)
    func show(items: [LanguageItem])
}

protocol ILanguageSettingsViewDelegate {
    func viewDidLoad()
    func didSelect(item: LanguageItem)
}

protocol ILanguageSettingsInteractor {
    var items: [LanguageItem] { get }
    func setCurrentLanguage(with item: LanguageItem)
}

protocol ILanguageSettingsInteractorDelegate: class {
    func didSetCurrentLanguage()
}

protocol ILanguageSettingsRouter {
    func reloadAppInterface()
}
