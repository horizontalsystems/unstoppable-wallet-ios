import Erc20Kit
import RxSwift
import RxCocoa
import BigInt

class Erc20AvailableBalanceService {
    private let erc20Kit: Kit

    init(erc20Kit: Kit) {
        self.erc20Kit = erc20Kit
    }

    var erc20Balance: BigUInt? {
        erc20Kit.balance
    }

}
