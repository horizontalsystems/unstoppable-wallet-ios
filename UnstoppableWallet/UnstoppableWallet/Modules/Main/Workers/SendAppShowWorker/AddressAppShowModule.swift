import RxSwift
import UIKit
import MarketKit

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

        guard var address = event as? String else {
            throw EventHandler.HandleError.noSuitableHandler
        }

        // Handle uri string if exist
        var uriBlockchainType: BlockchainType? = nil
        var addressData: AddressData? = nil
        if AddressUriParser.hasUriPrefix(text: address) {
            let data = AddressParserFactory.uriBlockchainTypes.map { type -> AddressUriParser in
                AddressParserFactory.parser(blockchainType: type)
            }.compactMap { parser in
                switch parser.parse(paymentAddress: address) {
                case let .data(addressData):
                    return (parser.blockchainType, addressData)
                default: return nil
                }
            }.first

            // we can handle one of blockchain types. For .ethereum -> we must return nil, to check all Evm blockchains for now
            if let data {
                switch data.0 {
                case .ethereum: uriBlockchainType = nil
                default: uriBlockchainType = data.0
                }
            }
            addressData = data?.1
        }
        address = addressData?.address ?? address
        let disposeBag = DisposeBag()
        let chain = AddressParserFactory.parserChain(blockchainType: uriBlockchainType, withEns: false)
        let types = try await withCheckedThrowingContinuation { continuation in
            chain
                .handlers(address: address)
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

        guard let viewController = WalletModule.sendTokenListViewController(
                allowedBlockchainTypes: types,
                mode: .prefilled(address: address, amount: addressData?.amount.map { Decimal($0) })) else {
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
