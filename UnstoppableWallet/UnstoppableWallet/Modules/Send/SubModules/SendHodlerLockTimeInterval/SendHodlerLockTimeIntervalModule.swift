import Hodler

protocol ISendHodlerLockTimeIntervalRouter {
    func notifyAndClose(lockTimeInterval: HodlerPlugin.LockTimeInterval?)
}

protocol ISendHodlerLockTimeIntervalDelegate: AnyObject {
    func onSelect(lockTimeInterval: HodlerPlugin.LockTimeInterval?)
}
