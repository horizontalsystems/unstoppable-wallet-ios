import PinKit

class LockScreenPresenter {
    private let router: ILockScreenRouter

    init(router: ILockScreenRouter) {
        self.router = router
    }

}

extension LockScreenPresenter: IUnlockDelegate {

    func onUnlock() {
        router.dismiss()
    }

    func onCancelUnlock() {
    }

}

extension LockScreenPresenter: IChartOpener {

    func showChart(coinCode: String, coinTitle: String) {
        router.showChart(coinCode: coinCode, coinTitle: coinTitle)
    }

}
