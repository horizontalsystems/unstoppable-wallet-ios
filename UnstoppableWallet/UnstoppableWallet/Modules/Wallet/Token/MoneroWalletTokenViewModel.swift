import Combine
import Foundation

class MoneroWalletTokenViewModel: ObservableObject {
    private let adapterManager = Core.shared.adapterManager
    private let restoreSettingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)

    let wallet: Wallet

    @Published var birthdayHeight: Int?

    init(wallet: Wallet) {
        self.wallet = wallet

        birthdayHeight = restoreSettingsService.settings(accountId: wallet.account.id, blockchainType: wallet.token.blockchainType).birthdayHeight
    }
}

extension MoneroWalletTokenViewModel {
    func onChange(birthdayHeight: Int) {
        let blockchainType = wallet.token.blockchainType
        restoreSettingsService.set(birthdayHeight: String(birthdayHeight), account: wallet.account, blokcchainType: blockchainType)
        self.birthdayHeight = birthdayHeight

        adapterManager.recreateAdapter(blockchainType: blockchainType)
    }
}
