import CoinKit

protocol IDepositView: AnyObject {
    func set(viewItem: DepositModule.AddressViewItem)
    func showCopied()
}

protocol IDepositViewDelegate {
    func onLoad()
    func onTapAddress()
    func onTapShare()
    func onTapClose()
}

protocol IDepositInteractor {
    var address: String { get }
    func copy(address: String)
}

protocol IDepositInteractorDelegate: AnyObject {
}

protocol IDepositRouter {
    func showShare(address: String)
    func close()
}

class DepositModule {

    struct AddressViewItem {
        let coinTitle: String
        let coinCode: String
        let coinType: CoinType
        let address: String
        let additionalInfo: String?
    }

}
