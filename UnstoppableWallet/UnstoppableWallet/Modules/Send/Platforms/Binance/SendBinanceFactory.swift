import UIKit
import MarketKit
import HsToolKit

class SendBinanceFactory: BaseSendFactory {
    private let service: SendBinanceService
    private let fiatService: FiatService
    private let feeFiatService: FiatService
    private let addressService: AddressService
    private let memoService: SendMemoInputService
    private let logger: Logger
    private let platformCoin: PlatformCoin

    init(service: SendBinanceService, fiatService: FiatService, addressService: AddressService, memoService: SendMemoInputService, feeFiatService: FiatService, logger: Logger, platformCoin: PlatformCoin) {
        self.service = service
        self.fiatService = fiatService
        self.feeFiatService = feeFiatService
        self.addressService = addressService
        self.memoService = memoService
        self.logger = logger
        self.platformCoin = platformCoin
    }

    private func items() throws -> [ISendConfirmationViewItemNew] {
        var viewItems = [ISendConfirmationViewItemNew]()

        guard let address = addressService.state.address else {
            throw ConfirmationError.noAddress
        }

        let (coinValue, currencyValue) = try values(fiatService: fiatService)
        let (feeCoinValue, feeCurrencyValue) = try values(fiatService: feeFiatService)

        viewItems.append(SendConfirmationAmountViewItem(coinValue: coinValue, currencyValue: currencyValue, receiver: address))

        if let memo = memoService.memo, !memo.isEmpty {
            viewItems.append(SendConfirmationMemoViewItem(memo: memo))
        }

        viewItems.append(SendConfirmationFeeViewItem(coinValue: feeCoinValue, currencyValue: feeCurrencyValue))

        return viewItems
    }

}

extension SendBinanceFactory: ISendConfirmationFactory {

    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: service, logger: logger, platformCoin: platformCoin, items: items)
        let viewModel = SendConfirmationViewModel(service: service)
        let viewController = SendConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}
