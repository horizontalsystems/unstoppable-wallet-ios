class TermsInteractor {
    weak var delegate: ITermsInteractorDelegate?

    private let termsManager: ITermsManager
    private let appConfigProvider: IAppConfigProvider

    init(termsManager: ITermsManager, appConfigProvider: IAppConfigProvider) {
        self.termsManager = termsManager
        self.appConfigProvider = appConfigProvider
    }

}

extension TermsInteractor: ITermsInteractor {

    var terms: [Term] {
        termsManager.terms
    }

    var gitHubLink: String {
        appConfigProvider.appGitHubLink
    }

    var siteLink: String {
        appConfigProvider.appWebPageLink
    }

    func update(term: Term) {
        termsManager.update(term: term)
    }

}
