class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let authManager: IAuthManager
    private let wordsManager: IWordsManager
    private let systemInfoManager: ISystemInfoManager

    init(authManager: IAuthManager, wordsManager: IWordsManager, systemInfoManager: ISystemInfoManager) {
        self.authManager = authManager
        self.wordsManager = wordsManager
        self.systemInfoManager = systemInfoManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            let words = try wordsManager.generateWords()
            try authManager.login(withWords: words, syncMode: .new)

            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

    var appVersion: String {
        return systemInfoManager.appVersion
    }

}
