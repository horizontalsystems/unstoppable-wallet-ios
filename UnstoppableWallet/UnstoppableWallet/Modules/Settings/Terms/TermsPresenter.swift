import PinKit

class TermsPresenter {
    weak var view: ITermsView?

    private let interactor: ITermsInteractor

    private var terms = [Term]()

    init(interactor: ITermsInteractor) {
        self.interactor = interactor
    }

}

extension TermsPresenter: ITermsViewDelegate {

    func viewDidLoad() {
        terms = interactor.terms
        view?.set(terms: terms)
    }

    func onTapTerm(index: Int) {
        terms[index].accepted = !terms[index].accepted

        interactor.update(term: terms[index])

        view?.set(terms: terms)
        view?.refresh()
    }

}
