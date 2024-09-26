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
        guard let deeplink = event as? String else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        let config = try await tonConnectManager.loadTonConnectConfiguration(deeplink: deeplink)

        await MainActor.run { [weak self] in
            let view = TonConnectConnectView(config: config)
            self?.parentViewController?.visibleController.present(view.toViewController(), animated: true)
        }
    }
}
