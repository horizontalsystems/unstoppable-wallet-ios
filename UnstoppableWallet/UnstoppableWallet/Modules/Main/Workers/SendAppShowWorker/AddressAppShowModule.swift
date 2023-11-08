import RxSwift
import UIKit

class AddressAppShowModule {
    private let disposeBag = DisposeBag()
    private let parentViewController: UIViewController?

    init(parentViewController: UIViewController?) {
        self.parentViewController = parentViewController
    }
}

extension AddressAppShowModule: IEventHandler {

    @MainActor
    func handle(event: Any, eventType: EventHandler.EventType) async throws {
        guard eventType.contains(.address) else {
            return
        }

        var uri: String?
        switch event {
        case let event as String:
            uri = event
        default: ()
        }

        guard let uri else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        let uriParser = AddressParserFactory.parser(blockchainType: <#T##BlockchainType?##MarketKit.BlockchainType?#>)

        let disposeBag = DisposeBag()
        let chain = AddressParserFactory.parserChain(blockchainType: nil, withEns: false)
        let types = try await withCheckedThrowingContinuation { continuation in
            chain
                .handlers(address: uri)
                .subscribe(onSuccess: { items in
                    continuation.resume(returning: items.map { $0.blockchainType })
                }, onError: { error in
                    continuation.resume(throwing: error)
                })
                .disposed(by: disposeBag)
        }

        guard !types.isEmpty else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        guard let viewController = WalletModule.sendTokenListViewController(allowedBlockchainTypes: types, prefilledAddress: uri) else {
            return
        }

        parentViewController?.visibleController.present(viewController, animated: true)
    }
}

extension AddressAppShowModule {
    static func handler(parentViewController: UIViewController? = nil) -> IEventHandler {
        AddressAppShowModule(parentViewController: parentViewController)
    }
}
