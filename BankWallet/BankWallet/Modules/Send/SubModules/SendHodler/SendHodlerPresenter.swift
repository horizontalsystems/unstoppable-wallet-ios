import Hodler

class SendHodlerPresenter {
    weak var view: ISendHodlerView?
    weak var delegate: ISendHodlerDelegate?

    private let router: ISendHodlerRouter

    var lockTimeInterval: HodlerPlugin.LockTimeInterval?

    init(router: ISendHodlerRouter) {
        self.router = router
    }

}

extension SendHodlerPresenter: ISendHodlerModule {

    var pluginData: [UInt8: IBitcoinPluginData] {
        guard let lockTimeInterval = lockTimeInterval else {
            return [:]
        }

        return [HodlerPlugin.id: HodlerData(lockTimeInterval: lockTimeInterval)]
    }

}

extension SendHodlerPresenter: ISendHodlerViewDelegate {

    func onLockTimeIntervalSelectorTap() {
        router.openLockTimeIntervals(selected: lockTimeInterval) { [weak self] selectedInterval in
            self?.lockTimeInterval = selectedInterval
            self?.view?.setLockTimeInterval(lockTimeInterval: selectedInterval)
            self?.delegate?.onUpdateLockTimeInterval()
        }
    }

}
