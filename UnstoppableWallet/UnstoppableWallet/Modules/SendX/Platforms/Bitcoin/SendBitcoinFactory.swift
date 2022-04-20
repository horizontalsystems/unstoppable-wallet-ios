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
    private let amountCautionService: AmountCautionService
    private let feeFiatService: FiatService
    private let feeService: SendFeeService
    private let feeRateService: SendXFeeRateService
    private let feePriorityService: SendXFeePriorityService
    private let addressService: AddressService
    private let timeLockService: SendXTimeLockService?
    private let adapterService: SendBitcoinAdapterService
    private let customFeeRateProvider: ICustomRangedFeeRateProvider?
    private let logger: Logger
    private let platformCoin: PlatformCoin

    init(fiatService: FiatService, amountCautionService: AmountCautionService, addressService: AddressService, feeFiatService: FiatService, feeService: SendFeeService, feeRateService: SendXFeeRateService, feePriorityService: SendXFeePriorityService, timeLockService: SendXTimeLockService?, adapterService: SendBitcoinAdapterService, customFeeRateProvider: ICustomRangedFeeRateProvider?, logger: Logger, platformCoin: PlatformCoin) {
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

        if (timeLockService?.lockTime ?? .none) != SendXTimeLockService.Item.none {
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
        let viewModel = SendXConfirmationViewModel(service: service)
        let viewController = SendXConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}

extension SendBitcoinFactory: ISendFeeSettingsFactory {

    func feeSettingsViewController() throws -> UIViewController {
        guard let customRangedFeeRateProvider = customFeeRateProvider else {
            throw AppError.unknownError
        }

        let feeViewModel = SendXFeeViewModel(service: feeService)
        let feeSliderService = SendXFeeSliderService(
                service: feePriorityService,
                feeRateService: feeRateService,
                customRangedFeeRateProvider: customRangedFeeRateProvider
        )
        let feeSliderViewModel = SendXFeeSliderViewModel(service: feeSliderService)
        let feePriorityViewModel = SendXFeePriorityViewModel(service: feePriorityService)
        let feeCautionViewModel = SendXFeeWarningViewModel(service: feeRateService)
        let amountCautionViewModel = SendFeeSettingsAmountCautionViewModel(
                service: amountCautionService,
                feeCoin: platformCoin
        )

        let service = SendXFeeSettingsService(feeService: feeService, feeRateService: feeRateService, feePriorityService: feePriorityService)
        let viewModel = SendXFeeSettingsViewModel(service: service)

        let viewController = SendXFeeSettingsViewController(
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
