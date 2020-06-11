class GuidePresenter {
    weak var view: IGuideView?

    private let parser: IGuideParser
    private let router: IGuideRouter
    private let interactor: IGuideInteractor

    private let guide: Guide
    private var fontSize: Int = 17

    init(guide: Guide, parser: IGuideParser, router: IGuideRouter, interactor: IGuideInteractor) {
        self.guide = guide
        self.parser = parser
        self.router = router
        self.interactor = interactor
    }

    private func syncViewItems() {
        view?.set(viewItems: parser.viewItems(markdownFileName: guide.fileName, fontSize: fontSize))
    }
}

extension GuidePresenter: IGuideViewDelegate {

    func onLoad() {
        syncViewItems()
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
}
