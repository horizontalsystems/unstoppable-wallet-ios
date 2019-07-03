//class SyncModeInteractor {
//    private let authManager: IAuthManager
//    private var wordsManager: IWordsManager
//
//    weak var delegate: ISyncModeInteractorDelegate?
//
//    init(authManager: IAuthManager, wordsManager: IWordsManager) {
//        self.authManager = authManager
//        self.wordsManager = wordsManager
//    }
//
//}
//
//extension SyncModeInteractor: ISyncModeInteractor {
//
//    func restore(with words: [String], syncMode: SyncMode) {
//        do {
//            try wordsManager.validate(words: words)
//            try authManager.login(withWords: words, syncMode: syncMode)
//            wordsManager.isBackedUp = true
//
//            delegate?.didRestore()
//        } catch {
//            delegate?.didFailToRestore(withError: error)
//        }
//    }
//
//    func reSync(syncMode: SyncMode) {
//
//    }
//
//}
//
//extension SyncModeInteractor: IAgreementDelegate {
//
//    func onConfirmAgreement() {
//        delegate?.didConfirmAgreement()
//    }
//
//}
