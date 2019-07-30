protocol IMainView: class {
}

protocol IMainViewDelegate {
    func viewDidLoad()
}

protocol IMainInteractor {
    func setDidShowMainOnce()
}

protocol IMainInteractorDelegate: class {
}

protocol IMainRouter {
}
