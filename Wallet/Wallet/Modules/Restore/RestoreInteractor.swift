class RestoreInteractor {
    weak var delegate: IRestoreInteractorDelegate?

    private let wordsManager: IWordsManager
    private let adapterManager: IAdapterManager

    init(wordsManager: IWordsManager, adapterManager: IAdapterManager) {
        self.wordsManager = wordsManager
        self.adapterManager = adapterManager
    }
}

extension RestoreInteractor: IRestoreInteractor {

    func validate(words: [String]) {
        do {
            try wordsManager.validate(words: words)
            delegate?.didValidate()
        } catch {
            delegate?.didFailToValidate(withError: error)
        }
    }

    func restore(withWords words: [String]) {
        do {
            try wordsManager.restore(withWords: words)
            adapterManager.start()
            delegate?.didRestore()
        } catch {
            delegate?.didFailToRestore(withError: error)
        }
    }

}
