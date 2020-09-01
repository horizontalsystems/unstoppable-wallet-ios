protocol IDerivationSettingView: class {
    func set(coinTitle: String, coinCode: String, blockchainType: String?)
    func set(viewItems: [DerivationSettingModule.ViewItem])
}

protocol IDerivationSettingViewDelegate {
    func onLoad()
    func onTapViewItem(index: Int)
    func onTapDone()
    func onBeforeClose()
}

protocol IDerivationSettingRouter {
    func close()
}

protocol IDerivationSettingDelegate: AnyObject {
    func onSelect(derivationSetting: DerivationSetting, coin: Coin)
    func onCancelSelectDerivation(coin: Coin)
}

class DerivationSettingModule {

    struct ViewItem {
        let title: String
        let subtitle: String
        let selected: Bool
    }

}
