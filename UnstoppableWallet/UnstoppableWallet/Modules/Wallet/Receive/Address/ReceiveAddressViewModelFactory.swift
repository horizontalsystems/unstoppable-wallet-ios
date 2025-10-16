import MarketKit
import SwiftUI

class ReceiveAddressViewModelFactory: ObservableObject {
    private let wallet: Wallet
    private var viewModels: [DepositAddressType: ReceiveAddressViewModel] = [:]

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    func viewModel(for type: DepositAddressType) -> ReceiveAddressViewModel {
        if let existingViewModel = viewModels[type] {
            return existingViewModel
        }

        let newViewModel = ReceiveAddressViewModel.instance(wallet: wallet, type: type)
        viewModels[type] = newViewModel

        return newViewModel
    }

    var title: String {
        "deposit.receive_coin".localized(wallet.coin.code)
    }
}
