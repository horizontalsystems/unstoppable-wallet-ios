import UIKit
import MarketKit
import HsToolKit
import CurrencyKit

protocol ISendConfirmationFactory {
    func confirmationViewController() throws -> UIViewController
}

protocol ISendFeeSettingsFactory {
    func feeSettingsViewController() throws -> UIViewController
}

class BaseSendFactory {

    func values(fiatService: FiatService) throws -> (CoinValue, CurrencyValue?) {
        guard let token = fiatService.token else {
            throw ConfirmationError.noCoin
        }

        var coinValue: CoinValue?
        var currencyValue: CurrencyValue?

        switch fiatService.primaryInfo {
        case .amount(let value):
            coinValue = CoinValue(kind: .token(token: token), value: value)
        case .amountInfo(let info):
            guard let info = info else {
                throw ConfirmationError.noAmount
            }

            switch info {
            case .coinValue(let value): coinValue = value
            case .currencyValue(let value): currencyValue = value
            }
        }

        if let info = fiatService.secondaryAmountInfo {
            switch info {
            case .coinValue(let value): coinValue = value
            case .currencyValue(let value): currencyValue = value
            }
        }

        guard let coinValue = coinValue else {
            throw ConfirmationError.noAmount
        }

        let negativeCoinValue = CoinValue(kind: coinValue.kind, value: Decimal(sign: .minus, exponent: coinValue.value.exponent, significand: coinValue.value.significand))

        return (negativeCoinValue, currencyValue)
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
    private let feeRateService: FeeRateService
    private let addressService: AddressService
    private let timeLockService: SendTimeLockService?
    private let adapterService: SendBitcoinAdapterService
    private let customFeeRateProvider: ICustomRangedFeeRateProvider?
    private let logger: Logger
    private let token: Token

    init(fiatService: FiatService, amountCautionService: SendAmountCautionService, addressService: AddressService, feeFiatService: FiatService, feeService: SendFeeService, feeRateService: FeeRateService, timeLockService: SendTimeLockService?, adapterService: SendBitcoinAdapterService, customFeeRateProvider: ICustomRangedFeeRateProvider?, logger: Logger, token: Token) {
        self.fiatService = fiatService
        self.amountCautionService = amountCautionService
        self.feeFiatService = feeFiatService
        self.feeService = feeService
        self.feeRateService = feeRateService
        self.addressService = addressService
        self.timeLockService = timeLockService
        self.adapterService = adapterService
        self.customFeeRateProvider = customFeeRateProvider
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
        viewItems.append(SendConfirmationFeeViewItem(coinValue: feeCoinValue, currencyValue: feeCurrencyValue))

        if (timeLockService?.lockTime ?? .none) != SendTimeLockService.Item.none {
            viewItems.append(SendConfirmationLockUntilViewItem(lockValue: timeLockService?.lockTime.title ?? "n/a".localized))
        }

        return viewItems
    }

}

extension SendBitcoinFactory: ISendConfirmationFactory {

    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: adapterService, logger: logger, token: token, items: items)
        let viewModel = SendConfirmationViewModel(service: service)
        let viewController = SendConfirmationViewController(viewModel: viewModel)

        return viewController
    }

}

extension SendBitcoinFactory: ISendFeeSettingsFactory {

    func feeSettingsViewController() throws -> UIViewController {
        let service = SendSettingsService(feeService: feeService, feeRateService: feeRateService, amountCautionService: amountCautionService, token: token)

        let viewModel = SendSettingsViewModel(service: service)
        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeRateViewModel = FeeRateViewModel(service: feeRateService)

        var dataSources: [ISendSettingsDataSource] = []

        if token.blockchainType == .bitcoin {
            dataSources.append(FeeRateDataSource(feeViewModel: feeViewModel, feeRateViewModel: feeRateViewModel))
        }

        let viewController = SendSettingsViewController(viewModel: viewModel, dataSources: dataSources)

        return viewController
    }

}
