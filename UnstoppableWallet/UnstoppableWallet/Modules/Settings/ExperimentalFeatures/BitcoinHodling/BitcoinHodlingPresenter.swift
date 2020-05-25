class BitcoinHodlingPresenter {
    weak var view: IBitcoinHodlingView?

    private let interactor: IBitcoinHodlingInteractor

    init(interactor: IBitcoinHodlingInteractor) {
        self.interactor = interactor
    }

}

extension BitcoinHodlingPresenter: IBitcoinHodlingViewDelegate {

    func onLoad() {
        view?.setLockTime(isOn: interactor.lockTimeEnabled)
    }

    func onSwitchLockTime(isOn: Bool) {
        interactor.lockTimeEnabled = isOn
    }

}
