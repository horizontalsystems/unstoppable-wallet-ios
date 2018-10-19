class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let wordsManager: IWordsManager
    private let walletManager: IWalletManager

    init(wordsManager: IWordsManager, walletManager: IWalletManager) {
        self.wordsManager = wordsManager
        self.walletManager = walletManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            try wordsManager.createWords()
            walletManager.initWallets()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
