import Foundation
import WalletKit

class DepositInteractor {

    weak var delegate: IDepositInteractorDelegate?

    var coins: [Coin]

    init(coins: [Coin]) {
        self.coins = coins
    }

}

extension DepositInteractor: IDepositInteractor {

}
