protocol ITermsView: AnyObject {
    func set(terms: [Term])
    func refresh()
}

protocol ITermsViewDelegate {
    func viewDidLoad()
    func onTapTerm(index: Int)
}

protocol ITermsInteractor: AnyObject {
    var terms: [Term] { get }
    func update(term: Term)
}
