class BlockchainSettingsListPresenter {
    weak var view: IBlockchainSettingsListView?

    private let proceedMode: RestoreRouter.ProceedMode
    private let router: IBlockchainSettingsListRouter
    private let interactor: IBlockchainSettingsListInteractor
    private let factory = BlockchainSettingsListViewItemFactory()

    private let selectedCoins: [Coin]
    private var currentSettings: [BlockchainSetting]

    private let canSave: Bool

    init(proceedMode: RestoreRouter.ProceedMode, router: IBlockchainSettingsListRouter, interactor: IBlockchainSettingsListInteractor, selectedCoins: [Coin], canSave: Bool) {
        self.proceedMode = proceedMode
        self.router = router
        self.interactor = interactor

        self.selectedCoins = selectedCoins
        self.currentSettings = interactor.blockchainSettings

        self.canSave = canSave
    }

    func updateUI() {
        view?.set(viewItems: factory.viewItems(settableCoins: interactor.settableCoins, selectedCoins: selectedCoins, currentSettings: currentSettings))
    }

}

extension BlockchainSettingsListPresenter: IBlockchainSettingsListViewDelegate {

    func onLoad() {
        switch proceedMode {
        case .next:
            view?.showNextButton()
        case .restore:
            view?.showRestoreButton()
        case .done:
            view?.showDoneButton()
        case .none: ()
        }

        updateUI()
    }

    func onConfirm() {
        router.notifyConfirm(settings: currentSettings)
    }

    func onSelect(index: Int) {
        router.showSettings(coin: interactor.settableCoins[index], settings: currentSettings[index], delegate: self)
    }

}

extension BlockchainSettingsListPresenter: IBlockchainSettingsUpdateDelegate {

    func onSelect(settings: BlockchainSetting, wallets: [Wallet]) {
        if let index = (currentSettings.firstIndex { $0.coinType == settings.coinType }) {
            currentSettings[index] = settings
        }

        updateUI()

        if canSave {
            interactor.save(settings: currentSettings)
            interactor.update(wallets: wallets)
        }
    }

}
