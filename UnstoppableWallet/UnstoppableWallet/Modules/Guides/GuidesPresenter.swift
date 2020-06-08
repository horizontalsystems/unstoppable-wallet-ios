import Foundation

class GuidesPresenter {
    weak var view: IGuidesView?

    private let router: IGuidesRouter
    private let interactor: IGuidesInteractor

    private var guides = [Guide]()
    private var viewItems = [GuideViewItem]()

    init(router: IGuidesRouter, interactor: IGuidesInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension GuidesPresenter: IGuidesViewDelegate {

    func onLoad() {
        guides = interactor.guides

        let viewItems = guides.map { guide in
            GuideViewItem(title: guide.title, date: guide.date, imageUrl: guide.imageUrl)
        }
        view?.set(viewItems: viewItems)
    }

    func onTapGuide(index: Int) {
        router.show(guide: guides[index])
    }

}

extension GuidesPresenter: IGuidesInteractorDelegate {
}
