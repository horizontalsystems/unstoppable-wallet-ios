class UnlinkInteractor {
    weak var delegate: IUnlinkInteractorDelegate?

    private let authManager: IAuthManager

    init(authManager: IAuthManager) {
        self.authManager = authManager
    }

}

extension UnlinkInteractor: IUnlinkInteractor {

    func unlink() {
        do {
            try authManager.logout()
            delegate?.didUnlink()
        } catch {
            // todo
        }
    }

}
