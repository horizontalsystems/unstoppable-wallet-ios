import UIKit
import MarketKit
import HsToolKit

protocol ISendConfirmationFactory {
    func confirmationViewController() throws -> UIViewController
}

protocol ISendFeeSettingsFactory {
    func feeSettingsViewController() throws -> UIViewController
}

class BaseSendFactory {

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

extension BaseSendFactory {

    enum ConfirmationError: Error {
        case noCoin
        case noAmount
        case noAddress
    }

}

class SendBitcoinFactory: BaseSendFactory {
    private let fiatService: FiatService
    private let amountCautionService: SendAmountCautionService
    private let feeFiatService: FiatService
    private let feeService: SendFeeService
    private let feeRateService: SendFeeRateService
    private let feePriorityService: SendFeePriorityService
    private let addressService: AddressService
    private let timeLockService: SendTimeLockService?
    private let adapterService: SendBitcoinAdapterService
    private let customFeeRateProvider: ICustomRangedFeeRateProvider?
    private let logger: Logger
    private let platformCoin: PlatformCoin

    init(fiatService: FiatService, amountCautionService: SendAmountCautionService, addressService: AddressService, feeFiatService: FiatService, feeService: SendFeeService, feeRateService: SendFeeRateService, feePriorityService: SendFeePriorityService, timeLockService: SendTimeLockService?, adapterService: SendBitcoinAdapterService, customFeeRateProvider: ICustomRangedFeeRateProvider?, logger: Logger, platformCoin: PlatformCoin) {
        self.fiatService = fiatService
        self.amountCautionService = amountCautionService
        self.feeFiatService = feeFiatService
        self.feeService = feeService
        self.feeRateService = feeRateService
        self.feePriorityService = feePriorityService
        self.addressService = addressService
        self.timeLockService = timeLockService
        self.adapterService = adapterService
        self.customFeeRateProvider = customFeeRateProvider
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

        if (timeLockService?.lockTime ?? .none) != SendTimeLockService.Item.none {
            viewItems.append(
                    SendConfirmationLockUntilViewItem(
                            lockValue: timeLockService?.lockTime.title ?? "n/a".localized
                    )
            )
        }

        return viewItems
    }

}

extension SendBitcoinFactory: ISendConfirmationFactory {

    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: adapterService, logger: logger, platformCoin: platformCoin, items: items)
        let viewModel = SendConfirmationViewModel(service: service)
        let viewController = SendConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}

extension SendBitcoinFactory: ISendFeeSettingsFactory {

    func feeSettingsViewController() throws -> UIViewController {
        guard let customRangedFeeRateProvider = customFeeRateProvider else {
            throw AppError.unknownError
        }

        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeSliderService = SendFeeSliderService(
                service: feePriorityService,
                feeRateService: feeRateService,
                customRangedFeeRateProvider: customRangedFeeRateProvider
        )
        let feeSliderViewModel = SendFeeSliderViewModel(service: feeSliderService)
        let feePriorityViewModel = SendFeePriorityViewModel(service: feePriorityService)
        let feeCautionViewModel = SendFeeWarningViewModel(service: feeRateService)
        let amountCautionViewModel = SendFeeSettingsAmountCautionViewModel(
                service: amountCautionService,
                feeCoin: platformCoin
        )

        let service = SendFeeSettingsService(feeService: feeService, feeRateService: feeRateService, feePriorityService: feePriorityService)
        let viewModel = SendFeeSettingsViewModel(service: service)

        let viewController = SendFeeSettingsViewController(
                viewModel: viewModel,
                feeViewModel: feeViewModel,
                feeSliderViewModel: feeSliderViewModel,
                feePriorityViewModel: feePriorityViewModel,
                feeCautionViewModel: feeCautionViewModel,
                amountCautionViewModel: amountCautionViewModel
        )

        return viewController
    }

}
