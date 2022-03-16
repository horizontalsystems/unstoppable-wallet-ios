import RxSwift

class DeepLinkService {
    private let deepLinkManager: DeepLinkManager

    init(deepLinkManager: DeepLinkManager) {
        self.deepLinkManager = deepLinkManager
    }

    var deepLinkObservable: Observable<DeepLinkManager.DeepLink?> {
        deepLinkManager.newSchemeObservable
    }

}
