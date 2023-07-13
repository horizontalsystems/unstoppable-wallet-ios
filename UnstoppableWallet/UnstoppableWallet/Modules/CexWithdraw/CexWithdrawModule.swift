import UIKit
import ThemeKit
import StorageKit

struct CexWithdrawModule {

    static func viewController(cexAsset: CexAsset) -> UIViewController? {
        let networks = cexAsset.withdrawNetworks

        guard let defaultNetwork = networks.first(where: { $0.isDefault }) ?? networks.first else {
            return nil
        }

        let addressService = AddressService(
            mode: .blockchainType,
            marketKit: App.shared.marketKit,
            contactBookManager: App.shared.contactManager,
            blockchainType: defaultNetwork.blockchain?.type
        )

        let service = CexWithdrawService(cexAsset: cexAsset, addressService: addressService, selectedNetwork: defaultNetwork)
        let switchService = AmountTypeSwitchService(localStorage: StorageKit.LocalStorage.default)
        let fiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)

        switchService.add(toggleAllowedObservable: fiatService.toggleAvailableObservable)

        let coinService = CexCoinService(cexAsset: cexAsset, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let availableBalanceViewModel = SendAvailableBalanceViewModel(service: service, coinService: coinService, switchService: switchService)

        let amountViewModel = CexAmountInputViewModel(
            service: service,
            fiatService: fiatService,
            switchService: switchService,
            decimalParser: AmountDecimalParser()
        )
        addressService.amountPublishService = amountViewModel

        let recipientViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let viewModel = CexWithdrawViewModel(service: service, coinService: coinService)

        return CexWithdrawViewController(
            viewModel: viewModel,
            availableBalanceViewModel: availableBalanceViewModel,
            amountViewModel: amountViewModel,
            recipientViewModel: recipientViewModel
        )
    }

}

extension CexWithdrawModule {

    struct SendData {
        let cexAsset: CexAsset
        let network: CexWithdrawNetwork?
        let address: String
        let amount: Decimal
        let feeFromAmount: Bool
        let fee: Decimal
    }

}
