class IntroPresenter {
    private let router: IIntroRouter

    init(router: IIntroRouter) {
        self.router = router
    }

}

extension IntroPresenter: IIntroViewDelegate {

    func didTapSkip() {
        router.showWelcome()
    }

    func didTapGetStarted() {
        router.showWelcome()
    }

}
