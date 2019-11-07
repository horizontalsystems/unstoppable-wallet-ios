import Hodler

protocol ISendHodlerView: class {
    func setLockTimeInterval(lockTimeInterval: HodlerPlugin.LockTimeInterval?)
}

protocol ISendHodlerViewDelegate {
    func onLockTimeIntervalSelectorTap()
}

protocol ISendHodlerRouter {
    func openLockTimeIntervals(selected: HodlerPlugin.LockTimeInterval?, onSelect: @escaping (HodlerPlugin.LockTimeInterval?) -> ())
}

protocol ISendHodlerDelegate: class {
    func onUpdateLockTimeInterval()
}

protocol ISendHodlerModule: AnyObject {
    var delegate: ISendHodlerDelegate? { get set }
    var pluginData: [UInt8: IBitcoinPluginData] { get }
    var lockTimeInterval: HodlerPlugin.LockTimeInterval? { get }
}

extension HodlerPlugin.LockTimeInterval {

    var title: String {
        switch self {
        case .hour: return "send.hodler_locktime_hour".localized
        case .month: return "send.hodler_locktime_month".localized
        case .halfYear: return "send.hodler_locktime_half_year".localized
        case .year: return "send.hodler_locktime_year".localized
        }
    }

}
