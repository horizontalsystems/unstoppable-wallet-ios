protocol IUnlinkView: class {
    func showSuccess()
}

protocol IUnlinkViewDelegate {
    var title: String { get }
    var coinCodes: String { get }

    func didTapUnlink()
}

protocol IUnlinkInteractor {
    func unlink(account: Account)
}

protocol IUnlinkInteractorDelegate: class {
}

protocol IUnlinkRouter {
    func dismiss()
}
