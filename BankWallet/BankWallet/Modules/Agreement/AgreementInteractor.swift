class AgreementInteractor {
    weak var delegate: IAgreementInteractorDelegate?

    private let localStorage: ILocalStorage

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage
    }

}

extension AgreementInteractor: IAgreementInteractor {

    func setConfirmed() {
        localStorage.agreementAccepted = true
    }

}
