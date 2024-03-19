import HsToolKit
import MarketKit
import SwiftUI
import UIKit

protocol ISendConfirmationFactory {
    func confirmationViewController() throws -> UIViewController
}

protocol ISendFeeSettingsFactory {
    func feeSettingsViewController() throws -> UIViewController
}

protocol ISendOutputSelectorFactory {
    func outputSelectorView() throws -> any View
}

class BaseSendFactory {
    func values(fiatService: FiatService) throws -> (CoinValue, CurrencyValue?) {
        guard let token = fiatService.token else {
            throw ConfirmationError.noCoin
        }

        var coinValue: CoinValue?
        var currencyValue: CurrencyValue?

        switch fiatService.primaryInfo {
        case let .amount(value):
            coinValue = CoinValue(kind: .token(token: token), value: value)
        case let .amountInfo(info):
            guard let info else {
                throw ConfirmationError.noAmount
            }

            switch info {
            case let .coinValue(value): coinValue = value
            case let .currencyValue(value): currencyValue = value
            }
        }

        if let info = fiatService.secondaryAmountInfo {
            switch info {
            case let .coinValue(value): coinValue = value
            case let .currencyValue(value): currencyValue = value
            }
        }

        guard let coinValue else {
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
    private let timeLockService: TimeLockService?
    private let memoService: SendMemoInputService
    private let adapterService: SendBitcoinAdapterService
    private let logger: Logger
    private let token: Token

    init(fiatService: FiatService, amountCautionService: SendAmountCautionService, addressService: AddressService, memoService: SendMemoInputService, feeFiatService: FiatService, feeService: SendFeeService, feeRateService: FeeRateService, timeLockService: TimeLockService?, adapterService: SendBitcoinAdapterService, logger: Logger, token: Token) {
        self.fiatService = fiatService
        self.amountCautionService = amountCautionService
        self.feeFiatService = feeFiatService
        self.feeService = feeService
        self.feeRateService = feeRateService
        self.addressService = addressService
        self.memoService = memoService
        self.timeLockService = timeLockService
        self.adapterService = adapterService
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

        if !App.shared.btcBlockchainManager.transactionRbfEnabled(blockchainType: token.blockchainType) {
            viewItems.append(SendConfirmationDisabledRbfViewItem())
        }

        if (timeLockService?.lockTime ?? .none) != TimeLockService.Item.none {
            viewItems.append(SendConfirmationLockUntilViewItem(lockValue: timeLockService?.lockTime.title ?? "n/a".localized))
        }

        return viewItems
    }
}

extension SendBitcoinFactory: ISendConfirmationFactory {
    func confirmationViewController() throws -> UIViewController {
        let items = try items()

        let service = SendConfirmationService(sendService: adapterService, logger: logger, token: token, items: items)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: token.blockchainType)
        let viewModel = SendConfirmationViewModel(service: service, contactLabelService: contactLabelService)
        let viewController = SendConfirmationViewController(viewModel: viewModel)

        return viewController
    }
}

extension SendBitcoinFactory: ISendFeeSettingsFactory {
    func feeSettingsViewController() throws -> UIViewController {
        var dataSources: [ISendSettingsDataSource] = []

        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeCautionViewModel = SendFeeCautionViewModel(service: feeRateService)
        let amountCautionViewModel = SendFeeSettingsAmountCautionViewModel(service: amountCautionService, feeToken: token)
        let feeRateViewModel = FeeRateViewModel(service: feeRateService, feeCautionViewModel: feeCautionViewModel, amountCautionViewModel: amountCautionViewModel)
        if token.blockchainType == .bitcoin {
            dataSources.append(FeeRateDataSource(feeViewModel: feeViewModel, feeRateViewModel: feeRateViewModel))
        }

        let inputOutputOrderViewModel = InputOutputOrderViewModel(service: adapterService.inputOutputOrderService)
        dataSources.append(InputOutputOrderDataSource(viewModel: inputOutputOrderViewModel))

        let rbfViewModel = RbfViewModel(service: adapterService.rbfService)
        dataSources.append(RbfDataSource(viewModel: rbfViewModel))

        if let timeLockService {
            let timeLockViewModel = TimeLockViewModel(service: timeLockService)
            dataSources.append(TimeLockDataSource(viewModel: timeLockViewModel))
        }

        let viewController = SendSettingsViewController(dataSources: dataSources)

        return viewController
    }
}

extension SendBitcoinFactory: ISendOutputSelectorFactory {
    func outputSelectorView() throws -> any View {
        let addressViewModel = AddressOutputSelectorViewModel(addressService: addressService)
        let feeViewModel = SendFeeViewModel(service: feeService)
        let amountViewModel = AmountOutputSelectorViewModel(fiatService: fiatService)

        let switchService = AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage)
        let outputSelectorFiatService = BaseFiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        outputSelectorFiatService.set(token: token)

        let viewModel = OutputSelectorViewModel(adapterService: adapterService, fiatService: outputSelectorFiatService)
        return OutputSelectorView(amountViewModel: amountViewModel, addressViewModel: addressViewModel, feeViewModel: feeViewModel, viewModel: viewModel)
    }
}
