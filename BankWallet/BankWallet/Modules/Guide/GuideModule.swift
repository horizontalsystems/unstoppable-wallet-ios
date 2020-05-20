protocol IGuideView: AnyObject {
    func load(url: String)
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
