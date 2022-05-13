class TermsInteractor {
    private let termsManager: TermsManager

    init(termsManager: TermsManager) {
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
