import PinKit

class TermsPresenter {
    weak var view: ITermsView?

    private let router: ITermsRouter
    private let interactor: ITermsInteractor

    private var terms = [Term]()

    init(router: ITermsRouter, interactor: ITermsInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension TermsPresenter: ITermsViewDelegate {

    func viewDidLoad() {
        terms = interactor.terms
        view?.set(terms: terms)
    }

    func onTapGitHubButton() {
        router.open(link: interactor.gitHubLink)
    }

    func onTapSiteButton() {
        router.open(link: interactor.siteLink)
    }

    func onTapTerm(index: Int) {
        terms[index].accepted = !terms[index].accepted

        interactor.update(term: terms[index])

        view?.set(terms: terms)
        view?.refresh()
    }

}

extension TermsPresenter: ITermsInteractorDelegate {

}
