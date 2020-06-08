protocol IGuideView: AnyObject {
    func set(imageUrl: String, viewItems: [GuideBlockViewItem])
}

protocol IGuideViewDelegate {
    func onLoad()
}

protocol IGuideInteractor {
}

protocol IGuideInteractorDelegate: AnyObject {
}

protocol IGuideRouter {
}

protocol IGuideParser {
    func viewItems(markdownFileName: String) -> [GuideBlockViewItem]
}
