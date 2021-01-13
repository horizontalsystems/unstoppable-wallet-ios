protocol IDepositView: class {
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
    func derivationSetting(coinType: CoinType) -> DerivationSetting?
    func copy(address: String)
}

protocol IDepositInteractorDelegate: class {
}

protocol IDepositRouter {
    func showShare(address: String)
    func close()
}

class DepositModule {

    struct AddressViewItem {
        let coinTitle: String
        let coinCode: String
        let blockchainType: String?
        let address: String
        let additionalInfo: String?
    }

}
