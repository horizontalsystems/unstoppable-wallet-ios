class PrivacyEthereumRpcModePresenter {
    weak var view: IPrivacyEthereumRpcModeView?
    weak var delegate: IPrivacyEthereumRpcModeDelegate?

    private let router: IPrivacyEthereumRpcModeRouter

    private var currentMode: EthereumRpcMode
    private let modes = EthereumRpcMode.allCases

    init(currentMode: EthereumRpcMode, router: IPrivacyEthereumRpcModeRouter) {
        self.currentMode = currentMode
        self.router = router
    }

    private func syncViewItems() {
        let viewItems = modes.map { mode in
            PrivacyEthereumRpcModeModule.ViewItem(
                    title: mode.title,
                    subtitle: mode.address,
                    selected: mode == currentMode
            )
        }
        view?.set(viewItems: viewItems)
    }

}

extension PrivacyEthereumRpcModePresenter: IPrivacyEthereumRpcModeViewDelegate {

    func onLoad() {
        syncViewItems()
    }

    func onTapViewItem(index: Int) {
        currentMode = modes[index]
        syncViewItems()
    }

    func onTapDone() {
        delegate?.onSelect(mode: currentMode)
        router.close()
    }

}
