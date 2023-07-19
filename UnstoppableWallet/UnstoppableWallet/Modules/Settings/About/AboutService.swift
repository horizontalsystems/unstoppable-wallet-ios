import RxSwift

class AboutService {
    private let termsManager: TermsManager
    private let systemInfoManager: SystemInfoManager
    private let rateAppManager: RateAppManager

    init(termsManager: TermsManager, systemInfoManager: SystemInfoManager, rateAppManager: RateAppManager) {
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
        self.rateAppManager = rateAppManager
    }

}

extension AboutService {

    var termsAccepted: Bool {
        termsManager.termsAccepted
    }

    var termsAcceptedObservable: Observable<Bool> {
        termsManager.termsAcceptedObservable
    }

    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    func rateApp() {
        rateAppManager.forceShow()
    }

}
