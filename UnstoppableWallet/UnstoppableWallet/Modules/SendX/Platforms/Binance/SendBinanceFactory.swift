import UIKit
import MarketKit
import HsToolKit

class SendBinanceFactory: BaseSendFactory {
    private let service: SendBinanceService
    private let fiatService: FiatService
    private let feeFiatService: FiatService
    private let addressService: AddressService
    private let memoService: MemoInputService
    private let logger: Logger
    private let platformCoin: PlatformCoin

    init(service: SendBinanceService, fiatService: FiatService, addressService: AddressService, memoService: MemoInputService, feeFiatService: FiatService, logger: Logger, platformCoin: PlatformCoin) {
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

        if let memo = memoService.memo, !memo.isEmpty {
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

extension SendBinanceFactory: ISendConfirmationFactory {

    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: service, logger: logger, platformCoin: platformCoin, items: items)
        let viewModel = SendXConfirmationViewModel(service: service)
        let viewController = SendXConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}
