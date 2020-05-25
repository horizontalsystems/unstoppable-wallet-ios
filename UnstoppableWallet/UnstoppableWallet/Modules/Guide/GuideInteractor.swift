class GuideInteractor {
    weak var delegate: IGuideInteractorDelegate?

    init() {
    }

}

extension GuideInteractor: IGuideInteractor {
}
