import Foundation

protocol IMainSettingsView: class {
    func set(backedUp: Bool)
    func set(baseCurrency: String)
    func set(language: String)
    func set(lightMode: Bool)
    func set(appVersion: String)
    func setTabItemBadge(count: Int)
}

protocol IMainSettingsViewDelegate {
    func viewDidLoad()
    func didTapSecurity()
    func didTapRestore()
    func didTapBaseCurrency()
    func didTapLanguage()
    func didSwitch(lightMode: Bool)
    func didTapAbout()
    func didTapAppLink()
}

protocol IMainSettingsInteractor {
    var nonBackedUpCount: Int { get }
    var currentLanguage: String { get }
    var baseCurrency: String { get }
    var lightMode: Bool { get }
    var appVersion: String { get }
    func set(lightMode: Bool)
}

protocol IMainSettingsInteractorDelegate: class {
    func didUpdateNonBackedUp(count: Int)
    func didUpdateBaseCurrency()
    func didUpdateLightMode()
}

protocol IMainSettingsRouter {
    func showSecuritySettings()
    func showRestore()
    func showBaseCurrencySettings()
    func showLanguageSettings()
    func showAbout()
    func openAppLink()
    func reloadAppInterface()
}
