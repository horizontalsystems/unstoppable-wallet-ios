protocol ITermsView: class {
    func set(terms: [Term])
    func refresh()
}

protocol ITermsViewDelegate {
    func viewDidLoad()
    func onTapGitHubButton()
    func onTapSiteButton()
    func onTapTerm(index: Int)
}

protocol ITermsInteractor: AnyObject {
    var terms: [Term] { get }
    var gitHubLink: String { get }
    var siteLink: String { get }
    func update(term: Term)
}

protocol ITermsInteractorDelegate: class {
}

protocol ITermsRouter {
    func open(link: String)
}
