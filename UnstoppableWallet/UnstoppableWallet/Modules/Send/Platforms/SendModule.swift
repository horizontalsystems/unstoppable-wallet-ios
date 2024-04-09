import MarketKit
import RxCocoa
import ThemeKit
import UIKit

protocol ITitledCautionViewModel {
    var cautionDriver: Driver<TitledCaution?> { get }
}

enum SendModule {
    static func controller(wallet: Wallet, mode: SendBaseService.Mode = .send) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.adapter(for: wallet) else {
            return nil
        }

        let token = wallet.token

        switch adapter {
        case let adapter as ISendBitcoinAdapter:
            return SendModule.viewController(token: token, mode: mode, adapter: adapter)
        case let adapter as ISendBinanceAdapter:
            return SendModule.viewController(token: token, mode: mode, adapter: adapter)
        case let adapter as ISendZcashAdapter:
            return SendModule.viewController(token: token, mode: mode, adapter: adapter)
        case let adapter as ISendEthereumAdapter:
            return SendEvmModule.viewController(token: token, mode: mode, adapter: adapter)
        case let adapter as ISendTronAdapter:
            return SendTronModule.viewController(token: token, mode: mode, adapter: adapter)
        case let adapter as ISendTonAdapter:
//            return SendModuleNew.view(adapter: adapter).toViewController()
            return Self.viewController(token: token, mode: mode, adapter: adapter)
        default: return nil
        }
    }

    private static func viewController(token: Token, mode: SendBaseService.Mode, adapter: ISendBitcoinAdapter) -> UIViewController? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(blockchainType: token.blockchainType) else {
            return nil
        }

        let switchService = AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage)
        let coinService = CoinService(token: token, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, amount: mode.amount ?? 0)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(token: token, amount: mode.amount ?? 0)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let bitcoinParserItem = BitcoinAddressParserItem(blockchainType: token.blockchainType, parserType: .adapter(adapter))
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: bitcoinParserItem, coinCode: token.coin.code, token: token)
        let addressParserChain = AddressParserChain()
            .append(handler: bitcoinParserItem)
            .append(handler: udnAddressParserItem)

        if let httpSyncSource = App.shared.evmSyncSourceManager.httpSyncSource(blockchainType: .ethereum),
           let ensAddressParserItem = EnsAddressParserItem(rpcSource: httpSyncSource.rpcSource, rawAddressParserItem: bitcoinParserItem)
        {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: token.blockchainType, tokenType: token.type)
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), marketKit: App.shared.marketKit, contactBookManager: App.shared.contactManager, blockchainType: token.blockchainType)

        let memoService = SendMemoInputService(maxSymbols: 80)

        // Fee
        let feeRateService = FeeRateService(provider: feeRateProvider)
        let feeFiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, amount: mode.amount ?? 0)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: token)
        let inputOutputOrderService = InputOutputOrderService(blockchainType: adapter.blockchainType, blockchainManager: App.shared.btcBlockchainManager, itemsList: TransactionDataSortMode.allCases)
        let rbfService = RbfService(blockchainType: adapter.blockchainType, blockchainManager: App.shared.btcBlockchainManager)

        // TimeLock
        var timeLockService: TimeLockService?
        var timeLockErrorService: SendTimeLockErrorService?

        if adapter.blockchainType == .bitcoin {
            let timeLockServiceInstance = TimeLockService()
            timeLockService = timeLockServiceInstance
            timeLockErrorService = SendTimeLockErrorService(timeLockService: timeLockServiceInstance, addressService: addressService, adapter: adapter)
        }

        let bitcoinAdapterService = SendBitcoinAdapterService(
            feeRateService: feeRateService,
            amountInputService: amountInputService,
            addressService: addressService,
            memoService: memoService,
            inputOutputOrderService: inputOutputOrderService,
            rbfService: rbfService,
            timeLockService: timeLockService,
            btcBlockchainManager: App.shared.btcBlockchainManager,
            adapter: adapter
        )
        let service = SendBitcoinService(
            amountService: amountInputService,
            amountCautionService: amountCautionService,
            addressService: addressService,
            adapterService: bitcoinAdapterService,
            feeRateService: feeRateService,
            timeLockErrorService: timeLockErrorService,
            reachabilityManager: App.shared.reachabilityManager,
            token: token,
            mode: mode
        )

        // Add dependencies
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        amountInputService.availableBalanceService = bitcoinAdapterService
        amountCautionService.availableBalanceService = bitcoinAdapterService
        amountCautionService.sendAmountBoundsService = bitcoinAdapterService

        addressService.customErrorService = timeLockErrorService

//        memoService.availableService = service
        feeService.feeValueService = bitcoinAdapterService

        // ViewModels
        let viewModel = SendViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: bitcoinAdapterService, coinService: coinService, switchService: switchService)
        let amountInputViewModel = AmountInputViewModel(
            service: amountInputService,
            fiatService: fiatService,
            switchService: switchService,
            decimalParser: AmountDecimalParser()
        )
        addressService.amountPublishService = amountInputViewModel

        let amountCautionViewModel = SendAmountCautionViewModel(
            service: amountCautionService,
            switchService: switchService,
            coinService: coinService
        )
        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let memoViewModel = SendMemoInputViewModel(service: memoService)

        // UnspentOutputs
        let unspentOutputsViewModel = UnspentOutputsViewModel(sendInfoService: bitcoinAdapterService)

        // Fee
        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeCautionViewModel = SendFeeCautionViewModel(service: feeRateService)

        let sendFactory = SendBitcoinFactory(
            fiatService: fiatService,
            amountCautionService: amountCautionService,
            addressService: addressService,
            memoService: memoService,
            feeFiatService: feeFiatService,
            feeService: feeService,
            feeRateService: feeRateService,
            timeLockService: timeLockService,
            adapterService: bitcoinAdapterService,
            logger: App.shared.logger,
            token: token
        )

        let viewController = SendBitcoinViewController(
            confirmationFactory: sendFactory,
            feeSettingsFactory: sendFactory,
            outputSelectorFactory: sendFactory,
            viewModel: viewModel,
            availableBalanceViewModel: availableBalanceViewModel,
            amountInputViewModel: amountInputViewModel,
            amountCautionViewModel: amountCautionViewModel,
            recipientViewModel: recipientViewModel,
            memoViewModel: memoViewModel,
            unspentOutputsViewModel: unspentOutputsViewModel,
            feeViewModel: feeViewModel,
            feeCautionViewModel: feeCautionViewModel
        )

        return viewController
    }

    private static func viewController(token: Token, mode: SendBaseService.Mode, adapter: ISendBinanceAdapter) -> UIViewController? {
        let feeToken = App.shared.feeCoinProvider.feeToken(token: token) ?? token

        let switchService = AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage)
        let coinService = CoinService(token: token, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, amount: mode.amount ?? 0)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(token: token, amount: mode.amount ?? 0)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let binanceParserItem = BinanceAddressParserItem(parserType: .adapter(adapter))
        let addressParserChain = AddressParserChain()
            .append(handler: binanceParserItem)

        let addressUriParser = AddressParserFactory.parser(blockchainType: token.blockchainType, tokenType: token.type)
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), marketKit: App.shared.marketKit, contactBookManager: App.shared.contactManager, blockchainType: token.blockchainType)

        let memoService = SendMemoInputService(maxSymbols: 120)

        // Fee
        let feeFiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, amount: mode.amount ?? 0)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: feeToken)

        let service = SendBinanceService(
            amountService: amountInputService,
            amountCautionService: amountCautionService,
            addressService: addressService,
            memoService: memoService,
            adapter: adapter,
            reachabilityManager: App.shared.reachabilityManager,
            token: token,
            mode: mode
        )

        // Add dependencies
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
        addressService.amountPublishService = amountInputViewModel

        let amountCautionViewModel = SendAmountCautionViewModel(
            service: amountCautionService,
            switchService: switchService,
            coinService: coinService
        )
        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let memoViewModel = SendMemoInputViewModel(service: memoService)

        // Fee
        let feeViewModel = SendFeeViewModel(service: feeService)
        let feeWarningViewModel = SendBinanceFeeWarningViewModel(adapter: adapter, coinCode: token.coin.code, feeToken: feeToken)

        // Confirmation and Settings
        let sendFactory = SendBinanceFactory(
            service: service,
            fiatService: fiatService,
            addressService: addressService,
            memoService: memoService,
            feeFiatService: feeFiatService,
            logger: App.shared.logger,
            token: token
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

        return viewController
    }

    private static func viewController(token: Token, mode: SendBaseService.Mode, adapter: ISendZcashAdapter) -> UIViewController? {
        let switchService = AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage)
        let coinService = CoinService(token: token, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, amount: mode.amount ?? 0)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(token: token, amount: mode.amount ?? 0)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let zcashParserItem = ZcashAddressParserItem(parserType: .adapter(adapter))
        let addressParserChain = AddressParserChain()
            .append(handler: zcashParserItem)

        let addressUriParser = AddressParserFactory.parser(blockchainType: token.blockchainType, tokenType: token.type)
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), marketKit: App.shared.marketKit, contactBookManager: App.shared.contactManager, blockchainType: token.blockchainType)

        let memoService = SendMemoInputService(maxSymbols: 120)

        // Fee
        let feeFiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit, amount: mode.amount ?? 0)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: token)

        let service = SendZcashService(
            amountService: amountInputService,
            amountCautionService: amountCautionService,
            addressService: addressService,
            memoService: memoService,
            adapter: adapter,
            reachabilityManager: App.shared.reachabilityManager,
            token: token,
            mode: mode
        )

        // Add dependencies
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
        addressService.amountPublishService = amountInputViewModel

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
            token: token
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

        return viewController
    }

    private static func viewController(token: Token, mode: SendBaseService.Mode, adapter: ISendTonAdapter) -> UIViewController? {
        let switchService = AmountTypeSwitchService(userDefaultsStorage: App.shared.userDefaultsStorage)
        let coinService = CoinService(token: token, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)

        // Amount
        let amountInputService = SendBitcoinAmountInputService(token: token)
        let amountCautionService = SendAmountCautionService(amountInputService: amountInputService)

        // Address
        let parserItem = TonAddressParserItem()
        let addressParserChain = AddressParserChain()
            .append(handler: parserItem)

        let addressUriParser = AddressParserFactory.parser(blockchainType: token.blockchainType, tokenType: token.type)
        let addressService = AddressService(mode: .parsers(addressUriParser, addressParserChain), marketKit: App.shared.marketKit, contactBookManager: App.shared.contactManager, blockchainType: token.blockchainType)

        let memoService = SendMemoInputService(maxSymbols: 120)

        // Fee
        let feeFiatService = FiatService(switchService: switchService, currencyManager: App.shared.currencyManager, marketKit: App.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeToken: token)

        let service = SendTonService(
            amountService: amountInputService,
            amountCautionService: amountCautionService,
            addressService: addressService,
            memoService: memoService,
            adapter: adapter,
            reachabilityManager: App.shared.reachabilityManager,
            token: token,
            mode: mode
        )

        // Add dependencies
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
        addressService.amountPublishService = amountInputViewModel

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
        let sendFactory = SendTonFactory(
            service: service,
            fiatService: fiatService,
            addressService: addressService,
            memoService: memoService,
            feeFiatService: feeFiatService,
            logger: App.shared.logger,
            token: token
        )

        let viewController = SendTonViewController(
            confirmationFactory: sendFactory,
            viewModel: viewModel,
            availableBalanceViewModel: availableBalanceViewModel,
            amountInputViewModel: amountInputViewModel,
            amountCautionViewModel: amountCautionViewModel,
            recipientViewModel: recipientViewModel,
            memoViewModel: memoViewModel,
            feeViewModel: feeViewModel
        )

        return viewController
    }
}
