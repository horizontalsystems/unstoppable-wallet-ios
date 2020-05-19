protocol IGuidesView: AnyObject {
}

protocol IGuidesViewDelegate {
    func onLoad()
}

protocol IGuidesInteractor {
}

protocol IGuidesInteractorDelegate: AnyObject {
}

protocol IGuidesRouter {
}

struct GuideViewItem {
    let title: String
    let large: Bool
    var coinCode: String?
    var imageUrl: String?
}
