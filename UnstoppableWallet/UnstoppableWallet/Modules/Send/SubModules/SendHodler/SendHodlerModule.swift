import Hodler

protocol ISendHodlerView: AnyObject {
    func setLockTimeInterval(lockTimeInterval: HodlerPlugin.LockTimeInterval?)
}

protocol ISendHodlerViewDelegate {
    func onLockTimeIntervalSelectorTap()
}

protocol ISendHodlerRouter {
    func openLockTimeIntervals(selected: HodlerPlugin.LockTimeInterval?, delegate: ISendHodlerLockTimeIntervalDelegate)
}

protocol ISendHodlerDelegate: AnyObject {
    func onUpdateLockTimeInterval()
}

protocol ISendHodlerModule: AnyObject {
    var delegate: ISendHodlerDelegate? { get set }
    var pluginData: [UInt8: IBitcoinPluginData] { get }
    var lockValue: String? { get }
}

extension HodlerPlugin.LockTimeInterval {

    static func title(lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> String {
        guard let lockTimeInterval = lockTimeInterval else {
            return "send.hodler_locktime_off".localized
        }

        switch lockTimeInterval {
        case .hour: return "send.hodler_locktime_hour".localized
        case .month: return "send.hodler_locktime_month".localized
        case .halfYear: return "send.hodler_locktime_half_year".localized
        case .year: return "send.hodler_locktime_year".localized
        }
    }

}
