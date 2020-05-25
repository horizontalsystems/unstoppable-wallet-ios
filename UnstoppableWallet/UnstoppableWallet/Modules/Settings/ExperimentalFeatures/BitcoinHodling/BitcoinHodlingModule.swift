protocol IBitcoinHodlingInteractor: AnyObject {
    var lockTimeEnabled: Bool { get set }
}

protocol IBitcoinHodlingView: AnyObject {
    func setLockTime(isOn: Bool)
}

protocol IBitcoinHodlingViewDelegate {
    func onLoad()
    func onSwitchLockTime(isOn: Bool)
}
