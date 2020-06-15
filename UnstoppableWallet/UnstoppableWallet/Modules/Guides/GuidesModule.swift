import Foundation

protocol IGuidesView: AnyObject {
    func set(filterViewItems: [FilterHeaderView.ViewItem])
    func set(viewItems: [GuideViewItem])
    func refresh()
    func setSpinner(visible: Bool)
}

protocol IGuidesViewDelegate {
    func onLoad()
    func onSelectFilter(index: Int)
    func onTapGuide(index: Int)
}

protocol IGuidesInteractor {
    func fetchGuideCategories()
}

protocol IGuidesInteractorDelegate: AnyObject {
    func didFetch(guideCategories: [GuideCategory])
}

protocol IGuidesRouter {
    func show(guide: Guide)
}

struct GuideViewItem {
    let title: String
    let date: Date
    var imageUrl: String?
}
