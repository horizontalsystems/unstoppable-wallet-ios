import Combine
import Foundation

class DeepLinkService {
    private var cancellables = Set<AnyCancellable>()
    private let deepLinkManager: DeepLinkManager

    private(set) var deepLink: DeepLinkManager.DeepLink?

    init(deepLinkManager: DeepLinkManager) {
        self.deepLinkManager = deepLinkManager
    }

    func setDeepLinkShown() {
        deepLinkManager.setDeepLinkShown()
    }
}
