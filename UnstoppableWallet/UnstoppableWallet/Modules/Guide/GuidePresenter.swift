class GuidePresenter {
    weak var view: IGuideView?

    private let router: IGuideRouter
    private let interactor: IGuideInteractor

    private let url: String

    init(url: String, router: IGuideRouter, interactor: IGuideInteractor) {
        self.url = url
        self.router = router
        self.interactor = interactor
    }

}

extension GuidePresenter: IGuideViewDelegate {

    func onLoad() {
        view?.load(url: url)
    }

}

extension GuidePresenter: IGuideInteractorDelegate {
}
