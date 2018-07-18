import Foundation
import WalletKit

class DepositInteractor {

    weak var delegate: IDepositInteractorDelegate?

    var wallets: [WalletBalanceItem]

    init(wallets: [WalletBalanceItem]) {
        self.wallets = wallets
    }

}

extension DepositInteractor: IDepositInteractor {

}
