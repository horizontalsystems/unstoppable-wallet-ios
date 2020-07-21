import CurrencyKit

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
    func didTapAppStatus()
    func didTapExperimentalFeatures()
    func didTapNotifications()
    func didTapBaseCurrency()
    func didTapLanguage()
    func didSwitch(lightMode: Bool)
    func didTapTerms()
    func didTapTellFriends()
    func didTapContact()
    func didTapCompanyLink()
    func onManageAccounts()
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
    func showManageAccounts()
    func showSecuritySettings()
    func showAppStatus()
    func showExperimentalFeatures()
    func showNotificationSettings()
    func showBaseCurrencySettings()
    func showLanguageSettings()
    func showTerms()
    func showShare(appWebPageLink: String)
    func showContact()
    func open(link: String)
    func reloadAppInterface()
}
