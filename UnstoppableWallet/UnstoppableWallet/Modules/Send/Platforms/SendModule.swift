import UIKit
import ThemeKit
import MarketKit
import StorageKit
import RxCocoa

protocol ITitledCautionViewModel {
    var cautionDriver: Driver<TitledCaution?> { get }
}

class SendModule {

    static func controller(wallet: Wallet) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.adapter(for: wallet) else {
            return nil
        }

        let platformCoin = wallet.platformCoin

        switch adapter {
        case let adapter as ISendBitcoinAdapter:
            return SendModule.viewController(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendBinanceAdapter:
            return SendModule.viewController(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendZcashAdapter:
            return SendModule.viewController(platformCoin: platformCoin, adapter: adapter)
        case let adapter as ISendEthereumAdapter:
            return SendEvmModule.viewController(platformCoin: platformCoin, adapter: adapter)
        default: return nil
        }
    }

    private static func viewController(platformCoin: PlatformCoin, adapter: ISendBitcoinAdapter) -> UIViewController? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) else {
            return nil
        }

        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let coinService = CoinService(platformCoin: platformCoin, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(platformCoin: platformCoin)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let bitcoinParserItem = BitcoinAddressParserItem(adapter: adapter)
        let udnAddressParserItem = UDNAddressParserItem.item(rawAddressParserItem: bitcoinParserItem, coinCode: platformCoin.code, coinType: platformCoin.coinType)
        let addressParserChain = AddressParserChain()
                .append(handler: bitcoinParserItem)
                .append(handler: udnAddressParserItem)

        let addressUriParser = AddressParserFactory.parser(coinType: platformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        // Fee
        let feePriorityService = SendFeePriorityService(provider: feeRateProvider)
        let feeRateService = SendFeeRateService(priorityService: feePriorityService, provider: feeRateProvider)
        let feeFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let feeService = SendBitcoinFeeService(fiatService: feeFiatService, feePriorityService: feePriorityService, feeCoin: platformCoin)

        // TimeLock
        var timeLockService: SendTimeLockService?
        var timeLockErrorService: SendTimeLockErrorService?
        var timeLockViewModel: SendTimeLockViewModel?

        if App.shared.localStorage.lockTimeEnabled, adapter.blockchain == .bitcoin {
            let timeLockServiceInstance = SendTimeLockService()
            timeLockService = timeLockServiceInstance
            timeLockErrorService = SendTimeLockErrorService(timeLockService: timeLockServiceInstance, addressService: addressService, adapter: adapter)
            timeLockViewModel = SendTimeLockViewModel(service: timeLockServiceInstance)
        }

        let bitcoinAdapterService = SendBitcoinAdapterService(
                feeRateService: feeRateService,
                amountInputService: amountInputService,
                addressService: addressService,
                timeLockService: timeLockService,
                btcBlockchainManager: App.shared.btcBlockchainManager,
                adapter: adapter
        )
        let service = SendBitcoinService(
                amountService: amountInputService,
                amountCautionService: amountCautionService,
                addressService: addressService,
                adapterService: bitcoinAdapterService,
                feeService: feeRateService,
                timeLockErrorService: timeLockErrorService,
                reachabilityManager: App.shared.reachabilityManager,
                platformCoin: platformCoin
        )

        //Add dependencies
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        amountInputService.availableBalanceService = bitcoinAdapterService
        amountCautionService.availableBalanceService = bitcoinAdapterService
        amountCautionService.sendAmountBoundsService = bitcoinAdapterService

        addressService.customErrorService = timeLockErrorService

        feeService.feeValueService = bitcoinAdapterService
        feePriorityService.feeRateService = feeRateService

        // ViewModels
        let viewModel = SendViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: bitcoinAdapterService, coinService: coinService, switchService: switchService)
        let amountInputViewModel = AmountInputViewModel(
                service: amountInputService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let amountCautionViewModel = SendAmountCautionViewModel(
                service: amountCautionService,
                switchService: switchService,
                coinService: coinService
        )
        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        // Fee
        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeWarningViewModel = SendFeeWarningViewModel(service: feeRateService)

        // Confirmation and Settings
        let customRangedFeeRateProvider = feeRateProvider as? ICustomRangedFeeRateProvider

        let sendFactory = SendBitcoinFactory(
                fiatService: fiatService,
                amountCautionService: amountCautionService,
                addressService: addressService,
                feeFiatService: feeFiatService,
                feeService: feeService,
                feeRateService: feeRateService,
                feePriorityService: feePriorityService,
                timeLockService: timeLockService,
                adapterService: bitcoinAdapterService,
                customFeeRateProvider: customRangedFeeRateProvider,
                logger: App.shared.logger,
                platformCoin: platformCoin
        )

        let viewController = SendBitcoinViewController(
                confirmationFactory: sendFactory,
                feeSettingsFactory: sendFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel,
                feeViewModel: feeViewModel,
                feeWarningViewModel: feeWarningViewModel,
                timeLockViewModel: timeLockViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func viewController(platformCoin: PlatformCoin, adapter: ISendBinanceAdapter) -> UIViewController? {
        let feeCoin = App.shared.feeCoinProvider.feeCoin(coinType: platformCoin.coinType) ?? platformCoin
        let feeCoinProtocol = App.shared.feeCoinProvider.feeCoinProtocol(coinType: platformCoin.coinType)

        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let coinService = CoinService(platformCoin: platformCoin, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(platformCoin: platformCoin)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let binanceParserItem = BinanceAddressParserItem(adapter: adapter)
        let addressParserChain = AddressParserChain()
                .append(handler: binanceParserItem)

        let addressUriParser = AddressParserFactory.parser(coinType: platformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        let memoService = SendMemoInputService(maxSymbols: 120)

        // Fee
        let feeFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeCoin: feeCoin)

        let service = SendBinanceService(
                amountService: amountInputService,
                amountCautionService: amountCautionService,
                addressService: addressService,
                memoService: memoService,
                adapter: adapter,
                reachabilityManager: App.shared.reachabilityManager,
                platformCoin: platformCoin
        )

        //Add dependencies
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        amountInputService.availableBalanceService = service
        amountCautionService.availableBalanceService = service

        feeService.feeValueService = service

        // ViewModels
        let viewModel = SendViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)
        let amountInputViewModel = AmountInputViewModel(
                service: amountInputService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let amountCautionViewModel = SendAmountCautionViewModel(
                service: amountCautionService,
                switchService: switchService,
                coinService: coinService
        )
        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let memoViewModel = SendMemoInputViewModel(service: memoService)

        // Fee
        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeWarningViewModel = SendBinanceFeeWarningViewModel(adapter: adapter, coinCode: platformCoin.code, coinProtocol: feeCoinProtocol, feeCoin: feeCoin)

        // Confirmation and Settings
        let sendFactory = SendBinanceFactory(
                service: service,
                fiatService: fiatService,
                addressService: addressService,
                memoService: memoService,
                feeFiatService: feeFiatService,
                logger: App.shared.logger,
                platformCoin: platformCoin
        )

        let viewController = SendBinanceViewController(
                confirmationFactory: sendFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel,
                memoViewModel: memoViewModel,
                feeViewModel: feeViewModel,
                feeWarningViewModel: feeWarningViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

    private static func viewController(platformCoin: PlatformCoin, adapter: ISendZcashAdapter) -> UIViewController? {
        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let coinService = CoinService(platformCoin: platformCoin, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(platformCoin: platformCoin)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let zcashParserItem = ZcashAddressParserItem(adapter: adapter)
        let addressParserChain = AddressParserChain()
                .append(handler: zcashParserItem)

        let addressUriParser = AddressParserFactory.parser(coinType: platformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        let memoService = SendMemoInputService(maxSymbols: 120)

        // Fee
        let feeFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeCoin: platformCoin)

        let service = SendZcashService(
                amountService: amountInputService,
                amountCautionService: amountCautionService,
                addressService: addressService,
                memoService: memoService,
                adapter: adapter,
                reachabilityManager: App.shared.reachabilityManager,
                platformCoin: platformCoin
        )

        //Add dependencies
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        amountInputService.availableBalanceService = service
        amountCautionService.availableBalanceService = service

        memoService.availableService = service
        feeService.feeValueService = service

        // ViewModels
        let viewModel = SendViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)
        let amountInputViewModel = AmountInputViewModel(
                service: amountInputService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let amountCautionViewModel = SendAmountCautionViewModel(
                service: amountCautionService,
                switchService: switchService,
                coinService: coinService
        )
        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let memoViewModel = SendMemoInputViewModel(service: memoService)

        // Fee
        let feeViewModel = SendFeeViewModel(service: feeService)

        // Confirmation and Settings
        let sendFactory = SendZcashFactory(
                service: service,
                fiatService: fiatService,
                addressService: addressService,
                memoService: memoService,
                feeFiatService: feeFiatService,
                logger: App.shared.logger,
                platformCoin: platformCoin
        )

        let viewController = SendZcashViewController(
                confirmationFactory: sendFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel,
                memoViewModel: memoViewModel,
                feeViewModel: feeViewModel
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
