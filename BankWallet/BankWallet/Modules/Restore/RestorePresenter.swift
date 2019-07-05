class RestorePresenter {
    weak var view: IRestoreView?

    private let interactor: IRestoreInteractor
    private let router: IRestoreRouter

    private var types = [PredefinedAccountType]()

    init(interactor: IRestoreInteractor, router: IRestoreRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension RestorePresenter: IRestoreInteractorDelegate {

    func didRestore() {
        router.close()
    }

}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        types = interactor.allTypes
    }

    var typesCount: Int {
        return types.count
    }

    func type(index: Int) -> PredefinedAccountType {
        return types[index]
    }

    func didSelect(index: Int) {
        switch types[index] {
        case .mnemonic: router.showRestoreWords()
        case .eos: ()
        case .binance: ()
        }
    }

    func didTapCancel() {
        router.close()
    }

}
