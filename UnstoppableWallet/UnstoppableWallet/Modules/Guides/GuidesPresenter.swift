import Foundation

class GuidesPresenter {
    weak var view: IGuidesView?

    private let router: IGuidesRouter
    private let interactor: IGuidesInteractor

    private var guideCategories = [GuideCategory]()
    private var viewItems = [GuideViewItem]()

    private var currentCategoryIndex: Int = 0

    init(router: IGuidesRouter, interactor: IGuidesInteractor) {
        self.router = router
        self.interactor = interactor
    }

    private func syncViewItems() {
        guard guideCategories.count > currentCategoryIndex else {
            return
        }

        let viewItems = guideCategories[currentCategoryIndex].guides.map { guide in
            GuideViewItem(
                    title: guide.title,
                    date: guide.date,
                    imageUrl: guide.imageUrl.flatMap { URL(string: $0, relativeTo: interactor.guidesIndexUrl) }
            )
        }
        view?.set(viewItems: viewItems)
    }
}

extension GuidesPresenter: IGuidesViewDelegate {

    func onLoad() {
        view?.setSpinner(visible: true)
        interactor.fetchGuideCategories(url: interactor.guidesIndexUrl)
    }

    func onSelectFilter(index: Int) {
        currentCategoryIndex = index

        syncViewItems()
        view?.refresh()
    }

    func onTapGuide(index: Int) {
        guard guideCategories.count > currentCategoryIndex else {
            return
        }

        let guide = guideCategories[currentCategoryIndex].guides[index]

        guard let guideUrl = URL(string: guide.fileUrl, relativeTo: interactor.guidesIndexUrl) else {
            return
        }

        router.show(guideUrl: guideUrl)
    }

}

extension GuidesPresenter: IGuidesInteractorDelegate {

    func didFetch(guideCategories: [GuideCategory]) {
        self.guideCategories = guideCategories

        view?.set(filterViewItems: guideCategories.map { category in
            FilterHeaderView.ViewItem.item(title: category.title)
        })

        view?.setSpinner(visible: false)
        syncViewItems()
        view?.refresh()
    }

}
