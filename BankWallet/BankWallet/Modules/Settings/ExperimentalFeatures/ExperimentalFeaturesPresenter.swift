class ExperimentalFeaturesPresenter {
    private let router: IExperimentalFeaturesRouter

    init(router: IExperimentalFeaturesRouter) {
        self.router = router
    }

}

extension ExperimentalFeaturesPresenter: IExperimentalFeaturesViewDelegate {

    func didTapBitcoinHodling() {
        router.showBitcoinHodling()
    }

}
