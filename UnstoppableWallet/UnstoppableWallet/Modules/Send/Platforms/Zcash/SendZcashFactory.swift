import UIKit
import MarketKit
import HsToolKit

class SendZcashFactory: BaseSendFactory {
    private let service: SendZcashService
    private let fiatService: FiatService
    private let feeFiatService: FiatService
    private let addressService: AddressService
    private let memoService: SendMemoInputService
    private let logger: Logger
    private let token: Token

    init(service: SendZcashService, fiatService: FiatService, addressService: AddressService, memoService: SendMemoInputService, feeFiatService: FiatService, logger: Logger, token: Token) {
        self.service = service
        self.fiatService = fiatService
        self.feeFiatService = feeFiatService
        self.addressService = addressService
        self.memoService = memoService
        self.logger = logger
        self.token = token
    }

    private func items() throws -> [ISendConfirmationViewItemNew] {
        var viewItems = [ISendConfirmationViewItemNew]()

        guard let address = addressService.state.address else {
            throw ConfirmationError.noAddress
        }

        let (coinValue, currencyValue) = try values(fiatService: fiatService)
        let (feeCoinValue, feeCurrencyValue) = try values(fiatService: feeFiatService)

        viewItems.append(SendConfirmationAmountViewItem(coinValue: coinValue, currencyValue: currencyValue, receiver: address))

        if memoService.isAvailable, let memo = memoService.memo, !memo.isEmpty {
            viewItems.append(SendConfirmationMemoViewItem(memo: memo))
        }

        viewItems.append(SendConfirmationFeeViewItem(coinValue: feeCoinValue, currencyValue: feeCurrencyValue))

        return viewItems
    }

}

extension SendZcashFactory: ISendConfirmationFactory {

    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: service, logger: logger, token: token, items: items)
        let viewModel = SendConfirmationViewModel(service: service)
        let viewController = SendConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}
