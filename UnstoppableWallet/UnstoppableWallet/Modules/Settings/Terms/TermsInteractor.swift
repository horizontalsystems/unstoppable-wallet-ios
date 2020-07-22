class TermsInteractor {
    weak var delegate: ITermsInteractorDelegate?

    private let termsManager: ITermsManager

    init(termsManager: ITermsManager) {
        self.termsManager = termsManager
    }

}

extension TermsInteractor: ITermsInteractor {

    var terms: [Term] {
        termsManager.terms
    }

    func update(term: Term) {
        termsManager.update(term: term)
    }

}
