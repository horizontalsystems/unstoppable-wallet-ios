class DerivationSettingPresenter {
    weak var view: IDerivationSettingView?
    weak var delegate: IDerivationSettingDelegate?

    private let router: IDerivationSettingRouter
    
    private let coin: Coin
    private var currentDerivation: MnemonicDerivation

    private let derivations = MnemonicDerivation.allCases
    private var didTapDone = false

    init(coin: Coin, currentDerivation: MnemonicDerivation, router: IDerivationSettingRouter) {
        self.coin = coin
        self.currentDerivation = currentDerivation
        self.router = router
    }

    private func syncViewItems() {
        let viewItems = derivations.map { derivation in
            DerivationSettingModule.ViewItem(
                    title: derivation.title,
                    subtitle: derivation.description(coinType: coin.type),
                    selected: derivation == currentDerivation
            )
        }
        view?.set(viewItems: viewItems)
    }

}

extension DerivationSettingPresenter: IDerivationSettingViewDelegate {

    func onLoad() {
        view?.set(coinTitle: coin.title, coinCode: coin.code, blockchainType: coin.type.blockchainType)
        syncViewItems()
    }

    func onTapViewItem(index: Int) {
        currentDerivation = derivations[index]
        syncViewItems()
    }

    func onTapDone() {
        let derivationSetting = DerivationSetting(coinType: coin.type, derivation: currentDerivation)
        delegate?.onSelect(derivationSetting: derivationSetting, coin: coin)

        didTapDone = true
        router.close()
    }

    func onBeforeClose() {
        guard !didTapDone else {
            return
        }

        delegate?.onCancelSelectDerivation(coin: coin)
    }

}
