protocol IUnlinkView: class {
}

protocol IUnlinkViewDelegate {
    func didTapUnlink()
}

protocol IUnlinkInteractor {
    func unlink()
}

protocol IUnlinkInteractorDelegate: class {
    func didUnlink()
}

protocol IUnlinkRouter {
    func showGuestModule()
}
