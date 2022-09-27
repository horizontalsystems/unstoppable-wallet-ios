import RxSwift

class AboutService {
    private let termsManager: TermsManager
    private let systemInfoManager: SystemInfoManager
    private let appConfigProvider: AppConfigProvider
    private let rateAppManager: RateAppManager

    init(termsManager: TermsManager, systemInfoManager: SystemInfoManager, appConfigProvider: AppConfigProvider, rateAppManager: RateAppManager) {
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
        self.appConfigProvider = appConfigProvider
        self.rateAppManager = rateAppManager
    }

}

extension AboutService {

    var appGitHubLink: String {
        appConfigProvider.appGitHubLink
    }

    var appWebPageLink: String {
        appConfigProvider.appWebPageLink
    }

    var contactEmail: String {
        appConfigProvider.reportEmail
    }

    var termsAccepted: Bool {
        termsManager.termsAccepted
    }

    var termsAcceptedObservable: Observable<Bool> {
        termsManager.termsAcceptedObservable
    }

    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    var twitterAccount: String {
        appConfigProvider.appTwitterAccount
    }

    func rateApp() {
        rateAppManager.forceShow()
    }

}
