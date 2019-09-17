protocol IRestoreOptionsView: class {
}

protocol IRestoreOptionsViewDelegate {
    func didSelectRestoreOptions(isFast: Bool)
}

protocol IRestoreOptionsRouter {
    func notifyDelegate(isFast: Bool)
}

protocol IRestoreOptionsDelegate: class {
    func onSelectRestoreOptions(isFast: Bool)
}
