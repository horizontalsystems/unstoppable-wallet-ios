import Hodler

protocol ISendHodlerView: class {
    func setLockTimeInterval(lockTimeInterval: HodlerPlugin.LockTimeInterval?)
}

protocol ISendHodlerViewDelegate {
    func onLockTimeIntervalSelectorTap()
}

protocol ISendHodlerRouter {
    func openLockTimeIntervals(selected: HodlerPlugin.LockTimeInterval?, lockTimeIntervalDelegate: ILockTimeIntervalDelegate)
}

protocol ISendHodlerDelegate: class {
    func onUpdateLockTimeInterval()
}

protocol ISendHodlerModule: AnyObject {
    var delegate: ISendHodlerDelegate? { get set }
    var pluginData: [UInt8: IBitcoinPluginData] { get }
}
