import Foundation

class GuidePresenter {
    weak var view: IGuideView?

    private let parser: IGuideParser
    private let router: IGuideRouter
    private let interactor: IGuideInteractor

    private let guideUrl: URL
    private var fontSize: Int = 17

    private var guideContent: String?

    init(guideUrl: URL, parser: IGuideParser, router: IGuideRouter, interactor: IGuideInteractor) {
        self.guideUrl = guideUrl
        self.parser = parser
        self.router = router
        self.interactor = interactor
    }

    private func syncViewItems() {
        guard let guideContent = guideContent else {
            return
        }

        view?.set(viewItems: parser.viewItems(guideContent: guideContent, guideUrl: guideUrl, fontSize: fontSize))
    }
}

extension GuidePresenter: IGuideViewDelegate {

    func onLoad() {
        view?.setSpinner(visible: true)
        interactor.fetchGuideContent(url: guideUrl)
    }

    func onTapGuide(url: URL) {
        guard let resolvedUrl = URL(string: url.absoluteString, relativeTo: guideUrl) else {
            return
        }

        router.showGuide(url: resolvedUrl)
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

        view?.setSpinner(visible: false)
        syncViewItems()
        view?.refresh()
    }

}
