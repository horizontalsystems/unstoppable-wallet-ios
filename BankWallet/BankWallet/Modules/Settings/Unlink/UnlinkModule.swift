protocol IUnlinkView: class {
}

protocol IUnlinkViewDelegate {
    func didTapUnlink()
}

protocol IUnlinkInteractor {
    func unlink(accountId: String)
}

protocol IUnlinkInteractorDelegate: class {
    func didUnlink()
}

protocol IUnlinkRouter {
    func dismiss()
}
