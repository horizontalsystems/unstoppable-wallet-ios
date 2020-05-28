protocol IGuideView: AnyObject {
    func set(title: String, imageUrl: String)
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
