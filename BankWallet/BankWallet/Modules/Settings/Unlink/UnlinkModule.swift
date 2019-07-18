protocol IUnlinkView: class {
}

protocol IUnlinkViewDelegate {
    func didTapUnlink()
}

protocol IUnlinkInteractor {
    func unlink(account: Account)
}

protocol IUnlinkInteractorDelegate: class {
    func didUnlink()
}

protocol IUnlinkRouter {
    func dismiss()
}
