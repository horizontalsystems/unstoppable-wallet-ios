import Combine
import UIKit

class TonConnectEventHandler {
    private let tonConnectManager = App.shared.tonConnectManager
    private var cancellables = Set<AnyCancellable>()

    private weak var parentViewController: UIViewController?

    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController

        tonConnectManager.sendTransactionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(sendTransactionRequest: $0) }
            .store(in: &cancellables)
    }

    private func handle(sendTransactionRequest: TonConnectSendTransactionRequest) {
        let view = TonConnectSendView(request: sendTransactionRequest)
        parentViewController?.visibleController.present(view.toViewController(), animated: true)
    }
}

extension TonConnectEventHandler: IEventHandler {
    func handle(source _: StatPage, event: Any, eventType _: EventHandler.EventType) async throws {
        var config: TonConnectConfig?
        let returnDeepLink: String?

        if case let .tonConnect(parameters) = event as? DeepLinkManager.DeepLink {
            config = try await tonConnectManager.loadTonConnectConfiguration(parameters: parameters)
            returnDeepLink = parameters.returnDeepLink
        } else if let deeplink = event as? String {
            config = try await tonConnectManager.loadTonConnectConfiguration(deeplink: deeplink)
            returnDeepLink = nil
        } else {
            returnDeepLink = nil
        }

        guard let config else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        await MainActor.run { [weak self] in
            let view = TonConnectConnectView(config: config, returnDeepLink: returnDeepLink)
            self?.parentViewController?.visibleController.present(view.toViewController(), animated: true)
        }
    }
}
