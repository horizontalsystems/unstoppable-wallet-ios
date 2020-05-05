class PrivacyInfoPresenter {
    weak var view: IPrivacyInfoView?

    private let router: IPrivacyInfoRouter

    init(router: IPrivacyInfoRouter) {
        self.router = router
    }

}

extension PrivacyInfoPresenter: IPrivacyInfoViewDelegate {

    func onClose() {
        router.close()
    }

}
