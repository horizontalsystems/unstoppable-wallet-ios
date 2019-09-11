protocol IMainSettingsView: class {
    func refresh()

    func set(allBackedUp: Bool)
    func set(currentBaseCurrency: String)
    func set(currentLanguage: String?)
    func set(lightMode: Bool)
    func set(appVersion: String)
}

protocol IMainSettingsViewDelegate {
    func viewDidLoad()
    func didTapSecurity()
    func didTapManageCoins()
    func didTapBaseCurrency()
    func didTapLanguage()
    func didSwitch(lightMode: Bool)
    func didTapAbout()
    func didTapTellFriends()
    func didTapReportProblem()
    func didTapCompanyLink()
}

protocol IMainSettingsInteractor: AnyObject {
    var companyWebPageLink: String { get }
    var appWebPageLink: String { get }
    var allBackedUp: Bool { get }
    var currentLanguageDisplayName: String? { get }
    var baseCurrency: Currency { get }
    var lightMode: Bool { get set }
    var appVersion: String { get }
}

protocol IMainSettingsInteractorDelegate: class {
    func didUpdate(allBackedUp: Bool)
    func didUpdateBaseCurrency()
}

protocol IMainSettingsRouter {
    func showSecuritySettings()
    func showManageCoins()
    func showBaseCurrencySettings()
    func showLanguageSettings()
    func showAbout()
    func showShare(appWebPageLink: String)
    func showReportProblem()
    func open(link: String)
    func reloadAppInterface()
}
