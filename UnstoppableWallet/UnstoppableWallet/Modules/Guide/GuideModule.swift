protocol IGuideView: AnyObject {
    func set(viewItems: [GuideBlockViewItem])
    func refresh()
    func setSpinner(visible: Bool)
}

protocol IGuideViewDelegate {
    func onLoad()
    func onTapFontSize()
}

protocol IGuideInteractor {
    func fetchGuideContent(url: String)
}

protocol IGuideInteractorDelegate: AnyObject {
    func didFetch(guideContent: String)
}

protocol IGuideRouter {
    func showFontSize(selected: Int, onSelect: @escaping (Int) -> ())
}

protocol IGuideParser {
    func viewItems(guideContent: String, fontSize: Int) -> [GuideBlockViewItem]
}
