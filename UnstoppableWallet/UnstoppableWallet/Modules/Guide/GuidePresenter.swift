class GuidePresenter {
    weak var view: IGuideView?

    private let parser: IGuideParser
    private let router: IGuideRouter
    private let interactor: IGuideInteractor

    private let guide: Guide

    init(guide: Guide, parser: IGuideParser, router: IGuideRouter, interactor: IGuideInteractor) {
        self.guide = guide
        self.parser = parser
        self.router = router
        self.interactor = interactor
    }

}

extension GuidePresenter: IGuideViewDelegate {

    func onLoad() {
        view?.set(imageUrl: guide.imageUrl, viewItems: parser.viewItems(markdownFileName: guide.fileName))
    }

}

extension GuidePresenter: IGuideInteractorDelegate {
}
