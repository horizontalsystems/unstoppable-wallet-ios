class PrivacyInfoPresenter {
    private let router: IPrivacyInfoRouter

    init(router: IPrivacyInfoRouter) {
        self.router = router
    }

}

extension PrivacyInfoPresenter: IPrivacyInfoViewDelegate {

    func onTapClose() {
        router.close()
    }

}
