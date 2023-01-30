import RxSwift

class DeepLinkService {
    private let disposeBag = DisposeBag()
    private let deepLinkManager: DeepLinkManager

    private(set) var deepLink: DeepLinkManager.DeepLink?

    init(deepLinkManager: DeepLinkManager) {
        self.deepLinkManager = deepLinkManager

        subscribe(disposeBag, deepLinkManager.newSchemeObservable) { deepLink in
            self.deepLink = deepLink
        }
    }

    func setDeepLinkShown() {
        deepLink = nil
    }

}
