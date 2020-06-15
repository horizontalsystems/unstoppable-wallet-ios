class GuidePresenter {
    weak var view: IGuideView?

    private let parser: IGuideParser
    private let router: IGuideRouter
    private let interactor: IGuideInteractor

    private let guide: Guide
    private var fontSize: Int = 17

    private var guideContent: String?

    init(guide: Guide, parser: IGuideParser, router: IGuideRouter, interactor: IGuideInteractor) {
        self.guide = guide
        self.parser = parser
        self.router = router
        self.interactor = interactor
    }

    private func syncViewItems() {
        guard let guideContent = guideContent else {
            return
        }

        view?.set(viewItems: parser.viewItems(guideContent: guideContent, fontSize: fontSize))
    }
}

extension GuidePresenter: IGuideViewDelegate {

    func onLoad() {
        interactor.fetchGuideContent(url: guide.fileUrl)
    }

    func onTapFontSize() {
        router.showFontSize(selected: fontSize) { [weak self] fontSize in
            self?.fontSize = fontSize
            self?.syncViewItems()
            self?.view?.refresh()
        }
    }

}

extension GuidePresenter: IGuideInteractorDelegate {

    func didFetch(guideContent: String) {
        self.guideContent = guideContent

        syncViewItems()
        view?.refresh()
    }

}
