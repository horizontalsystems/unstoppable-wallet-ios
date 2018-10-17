class GuestInteractor {
    weak var delegate: IGuestInteractorDelegate?

    private let wordsManager: IWordsManager
    private let adapterManager: IAdapterManager

    init(wordsManager: IWordsManager, adapterManager: IAdapterManager) {
        self.wordsManager = wordsManager
        self.adapterManager = adapterManager
    }
}

extension GuestInteractor: IGuestInteractor {

    func createWallet() {
        do {
            try wordsManager.createWords()
            adapterManager.start()
            delegate?.didCreateWallet()
        } catch {
            delegate?.didFailToCreateWallet(withError: error)
        }
    }

}
