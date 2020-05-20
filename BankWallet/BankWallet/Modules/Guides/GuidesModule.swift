protocol IGuidesView: AnyObject {
    func set(viewItems: [GuideViewItem])
}

protocol IGuidesViewDelegate {
    func onLoad()
    func onTapGuide(index: Int)
}

protocol IGuidesInteractor {
}

protocol IGuidesInteractorDelegate: AnyObject {
}

protocol IGuidesRouter {
    func showGuide(url: String)
}

struct GuideViewItem {
    let title: String
    let large: Bool
    let url: String
    var coinCode: String?
    var imageUrl: String?
}
