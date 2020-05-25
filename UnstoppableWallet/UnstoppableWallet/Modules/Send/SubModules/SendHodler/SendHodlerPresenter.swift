import Hodler

class SendHodlerPresenter {
    weak var view: ISendHodlerView?
    weak var delegate: ISendHodlerDelegate?

    private let router: ISendHodlerRouter

    private var lockTimeInterval: HodlerPlugin.LockTimeInterval?

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

    var lockValue: String? {
        lockTimeInterval.map { HodlerPlugin.LockTimeInterval.title(lockTimeInterval: $0) }
    }

}

extension SendHodlerPresenter: ISendHodlerViewDelegate {

    func onLockTimeIntervalSelectorTap() {
        router.openLockTimeIntervals(selected: lockTimeInterval, delegate: self)
    }

}

extension SendHodlerPresenter: ISendHodlerLockTimeIntervalDelegate {

    func onSelect(lockTimeInterval: HodlerPlugin.LockTimeInterval?) {
        self.lockTimeInterval = lockTimeInterval
        view?.setLockTimeInterval(lockTimeInterval: lockTimeInterval)
        delegate?.onUpdateLockTimeInterval()
    }

}
