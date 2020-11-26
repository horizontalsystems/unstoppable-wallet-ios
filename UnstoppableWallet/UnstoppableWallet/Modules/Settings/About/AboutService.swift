import RxSwift

class AboutService {
    private let termsManager: ITermsManager
    private let systemInfoManager: ISystemInfoManager
    private let appConfigProvider: IAppConfigProvider

    init(termsManager: ITermsManager, systemInfoManager: ISystemInfoManager, appConfigProvider: IAppConfigProvider) {
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
        self.appConfigProvider = appConfigProvider
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
        systemInfoManager.appVersion
    }

}
