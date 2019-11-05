import Hodler

protocol ILockTimeIntervalRouter {
    func dismiss(with: HodlerPlugin.LockTimeInterval?)
}

protocol ILockTimeIntervalDelegate: class {
    func onSelect(lockTimeInterval: HodlerPlugin.LockTimeInterval?)
}
