import RxSwift

class AboutService {
    private let termsManager: TermsManager
    private let systemInfoManager: SystemInfoManager

    init(termsManager: TermsManager, systemInfoManager: SystemInfoManager) {
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
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
}
