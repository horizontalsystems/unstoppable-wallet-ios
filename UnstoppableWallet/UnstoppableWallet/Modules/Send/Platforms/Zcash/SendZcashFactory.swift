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
    private let platformCoin: PlatformCoin

    init(service: SendZcashService, fiatService: FiatService, addressService: AddressService, memoService: SendMemoInputService, feeFiatService: FiatService, logger: Logger, platformCoin: PlatformCoin) {
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

        viewItems.append(
                SendConfirmationAmountViewItem(
                        primaryInfo: try primaryInfo(fiatService: fiatService),
                        secondaryInfo: fiatService.secondaryAmountInfo,
                        receiver: address)
        )

        if memoService.isAvailable, let memo = memoService.memo, !memo.isEmpty {
            viewItems.append(SendConfirmationMemoViewItem(memo: memo))
        }

        viewItems.append(
                SendConfirmationFeeViewItem(
                        primaryInfo: try primaryInfo(fiatService: feeFiatService),
                        secondaryInfo: feeFiatService.secondaryAmountInfo)
        )

        return viewItems
    }

}

extension SendZcashFactory: ISendConfirmationFactory {

    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: service, logger: logger, platformCoin: platformCoin, items: items)
        let viewModel = SendConfirmationViewModel(service: service)
        let viewController = SendConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}
