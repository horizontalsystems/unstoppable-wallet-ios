import RxSwift

class DeepLinkService {
    private let deepLinkManager: IDeepLinkManager

    init(deepLinkManager: IDeepLinkManager) {
        self.deepLinkManager = deepLinkManager
    }

    var deepLinkObservable: Observable<DeepLinkManager.DeepLink?> {
        deepLinkManager.newSchemeObservable
    }

}
