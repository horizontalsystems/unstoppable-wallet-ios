protocol IGuideView: AnyObject {
    func set(imageUrl: String, blocks: [GuideBlock])
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
