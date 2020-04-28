protocol IPrivacyEthereumRpcModeView: AnyObject {
    func set(viewItems: [PrivacyEthereumRpcModeModule.ViewItem])
}

protocol IPrivacyEthereumRpcModeViewDelegate {
    func onLoad()
    func onTapViewItem(index: Int)
    func onTapDone()
}

protocol IPrivacyEthereumRpcModeRouter {
    func close()
}

protocol IPrivacyEthereumRpcModeDelegate: AnyObject {
    func onSelect(mode: EthereumRpcMode)
}

class PrivacyEthereumRpcModeModule {

    struct ViewItem {
        let title: String
        let subtitle: String
        let selected: Bool
    }

}
