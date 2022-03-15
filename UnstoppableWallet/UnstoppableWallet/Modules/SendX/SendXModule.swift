import UIKit
import ThemeKit
import MarketKit
import StorageKit

class SendXModule {

    static func viewController(platformCoin: PlatformCoin, adapter: ISendBitcoinAdapter) -> UIViewController? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) else {
            return nil
        }

        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let coinService = CoinService(platformCoin: platformCoin, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        // Amount
        let amountInputService = SendXBitcoinAmountInputService(platformCoin: platformCoin)
        let amountCautionService = AmountCautionService(amountInputService: amountInputService)

        // Address
        let addressParserChain = AddressParserChain()
        let bitcoinParserItem = BitcoinAddressParserItem(adapter: adapter)
        addressParserChain.append(handler: bitcoinParserItem)
        addressParserChain.append(handler: UDNAddressParserItem(coinCode: "BTC", platformCoinCode: nil, chain: nil))

        let addressUriParser = AddressParserFactory.parser(coinType: platformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        // Fee
        let bitcoinFeeRateProvider = SendXBitcoinFeeRateAdjustmentService(amountInputService: amountInputService, coinService: coinService, feeRateProvider: feeRateProvider)
        let feePriorityService = SendXFeePriorityService(provider: bitcoinFeeRateProvider)
        let feeRateService = SendXFeeRateService(priorityService: feePriorityService, provider: bitcoinFeeRateProvider)
        let feeFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let feeService = SendFeeService(fiatService: feeFiatService, feeCoin: platformCoin)

        let bitcoinAdapterService = SendBitcoinAdapterService(
                feeRateService: feeRateService,
                amountInputService: amountInputService,
                addressService: addressService,
                transactionDataSortModeSettingsManager: App.shared.transactionDataSortModeSettingManager,
                adapter: adapter
        )
        let service = SendBitcoinService(
                amountService: amountInputService,
                amountCautionService: amountCautionService,
                addressService: addressService,
                adapterService: bitcoinAdapterService,
                feeService: feeRateService,
                reachabilityManager: App.shared.reachabilityManager,
                platformCoin: platformCoin
        )

        //Add dependencies
        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        amountInputService.availableBalanceService = bitcoinAdapterService
        amountCautionService.availableBalanceService = bitcoinAdapterService
        amountCautionService.sendAmountBoundsService = bitcoinAdapterService

        bitcoinFeeRateProvider.availableBalanceService = bitcoinAdapterService
        feeService.feeValueService = bitcoinAdapterService

        // ViewModels
        let viewModel = SendXViewModel(service: service)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: bitcoinAdapterService, coinService: coinService, switchService: switchService)
        let amountInputViewModel = AmountInputViewModel(
                service: amountInputService,
                fiatService: fiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let amountCautionViewModel = AmountCautionViewModel(
                service: amountCautionService,
                switchService: switchService,
                coinService: coinService
        )
        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        // Fee
        let feeViewModel = SendXFeeViewModel(service: feeService)
        let feeSliderViewModel = SendXFeeSliderViewModel(service: feePriorityService)
        let feePriorityViewModel = SendXFeePriorityViewModel(service: feePriorityService)
        let feeWarningViewModel = SendXFeeWarningViewModel(service: feeRateService)

        // Confirmation
        let confirmationFactory = SendBitcoinConfirmationFactory(
                fiatService: fiatService,
                addressService: addressService,
                feeFiatService: feeFiatService,
                adapterService: bitcoinAdapterService,
                logger: App.shared.logger,
                platformCoin: platformCoin
        )

        let viewController = SendXViewController(
                confirmationFactory: confirmationFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel,
                feeViewModel: feeViewModel,
                feeSliderViewModel: feeSliderViewModel,
                feePriorityViewModel: feePriorityViewModel,
                feeWarningViewModel: feeWarningViewModel
        )

        confirmationFactory.sourceViewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}
