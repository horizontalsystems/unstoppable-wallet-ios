protocol IGuideView: AnyObject {
    func set(viewItems: [GuideBlockViewItem])
    func refresh()
}

protocol IGuideViewDelegate {
    func onLoad()
    func onTapFontSize()
}

protocol IGuideInteractor {
}

protocol IGuideInteractorDelegate: AnyObject {
}

protocol IGuideRouter {
    func showFontSize(selected: Int, onSelect: @escaping (Int) -> ())
}

protocol IGuideParser {
    func viewItems(markdownFileName: String, fontSize: Int) -> [GuideBlockViewItem]
}
