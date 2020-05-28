protocol IGuidesView: AnyObject {
    func set(viewItems: [GuideViewItem])
}

protocol IGuidesViewDelegate {
    func onLoad()
    func onTapGuide(index: Int)
}

protocol IGuidesInteractor {
    var guides: [Guide] { get }
}

protocol IGuidesInteractorDelegate: AnyObject {
}

protocol IGuidesRouter {
    func show(guide: Guide)
}

struct GuideViewItem {
    let title: String
    let large: Bool
    var imageUrl: String?
}
