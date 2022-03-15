import UIKit
import MarketKit
import HsToolKit

protocol ISendConfirmationFactory {
    func viewController() throws -> UIViewController
}

class SendConfirmationFactory {

    func primaryInfo(fiatService: FiatService) throws -> AmountInfo {
        guard let platformCoin = fiatService.platformCoin else {
            throw ConfirmationError.noCoin
        }
        switch fiatService.primaryInfo {
        case .amount(let value):
            let coinValue = CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: value)
            return AmountInfo.coinValue(coinValue: coinValue)
        case .amountInfo(let info):
            guard let info = info else {
                throw ConfirmationError.noAmount
            }
            return info
        }
    }

}
extension SendConfirmationFactory {

    enum ConfirmationError: Error {
        case noCoin
        case noAmount
        case noAddress
    }

}

class SendBitcoinConfirmationFactory: SendConfirmationFactory {
    weak var sourceViewController: UIViewController?

    private let fiatService: FiatService
    private let feeFiatService: FiatService
    private let addressService: AddressService
    private let adapterService: SendBitcoinAdapterService
    private let logger: Logger
    private let platformCoin: PlatformCoin

    init(fiatService: FiatService, addressService: AddressService, feeFiatService: FiatService, adapterService: SendBitcoinAdapterService, logger: Logger, platformCoin: PlatformCoin) {
        self.fiatService = fiatService
        self.feeFiatService = feeFiatService
        self.addressService = addressService
        self.adapterService = adapterService
        self.logger = logger
        self.platformCoin = platformCoin
    }

    private func items() throws -> [ISendConfirmationViewItemNew] {
        var viewItems = [ISendConfirmationViewItemNew]()

        guard let address = addressService.state.address else {
            throw ConfirmationError.noAddress
        }

        viewItems.append(
                SendConfirmationAmountViewItem(
                        primaryInfo: try primaryInfo(fiatService: fiatService),
                        secondaryInfo: fiatService.secondaryAmountInfo,
                        receiver: address)
        )

        viewItems.append(
                SendConfirmationFeeViewItem(
                        primaryInfo: try primaryInfo(fiatService: feeFiatService),
                        secondaryInfo: feeFiatService.secondaryAmountInfo)
        )

        return viewItems
    }

}

extension SendBitcoinConfirmationFactory: ISendConfirmationFactory {

    func viewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: adapterService, logger: logger, platformCoin: platformCoin, items: items)
        let viewModel = SendXConfirmationViewModel(service: service)
        let viewController = SendXConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}
