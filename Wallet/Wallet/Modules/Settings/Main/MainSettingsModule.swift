import Foundation

protocol IMainSettingsView: class {
    func set(title: String)
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
    func didTapImportWallet()
    func didTapBaseCurrency()
    func didTapLanguage()
    func didSwitch(lightMode: Bool)
    func didTapAbout()
    func didTapAppLink()
}

protocol IMainSettingsInteractor {
    var isBackedUp: Bool { get }
    var currentLanguage: String { get }
    var baseCurrency: String { get }
    var lightMode: Bool { get }
    var appVersion: String { get }
    func set(lightMode: Bool)
}

protocol IMainSettingsInteractorDelegate: class {
    func didBackup()
    func didUpdate(baseCurrency: String)
    func didUpdateLightMode()
}

protocol IMainSettingsRouter {
    func showSecuritySettings()
    func showImportWallet()
    func showBaseCurrencySettings()
    func showLanguageSettings()
    func showAbout()
    func openAppLink()
    func reloadAppInterface()
}
