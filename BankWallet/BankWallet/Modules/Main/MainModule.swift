protocol IMainView: class {
}

protocol IMainViewDelegate {
    func viewDidLoad()
}

protocol IMainInteractor {
    func setMainShownOnce()
}

protocol IMainInteractorDelegate: class {
}

protocol IMainRouter {
}
