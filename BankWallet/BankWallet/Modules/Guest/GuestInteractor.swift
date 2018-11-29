class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let lockManager: ILockManager
    private let wordsManager: IWordsManager

    init(wordsManager: IWordsManager, lockManager: ILockManager) {
        self.lockManager = lockManager
        self.wordsManager = wordsManager
    }
}

extension GuestInteractor: IGuestInteractor {
    func willAppear() {
        lockManager.setLocking(deny: true)
    }

    func willDisAppear() {
        lockManager.setLocking(deny: false)
    }

    func createWallet() {
        do {
            try wordsManager.createWords()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
