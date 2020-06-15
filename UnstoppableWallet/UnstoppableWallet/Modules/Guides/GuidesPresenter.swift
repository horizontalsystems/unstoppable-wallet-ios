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
            GuideViewItem(title: guide.title, date: guide.date, imageUrl: guide.imageUrl)
        }
        view?.set(viewItems: viewItems)
    }
}

extension GuidesPresenter: IGuidesViewDelegate {

    func onLoad() {
        interactor.fetchGuideCategories()
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

        router.show(guide: guideCategories[currentCategoryIndex].guides[index])
    }

}

extension GuidesPresenter: IGuidesInteractorDelegate {

    func didFetch(guideCategories: [GuideCategory]) {
        self.guideCategories = guideCategories

        view?.set(filterViewItems: guideCategories.map { category in
            FilterHeaderView.ViewItem.item(title: category.title)
        })

        syncViewItems()
        view?.refresh()
    }

}
