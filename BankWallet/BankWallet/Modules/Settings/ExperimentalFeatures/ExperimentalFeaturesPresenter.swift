class ExperimentalFeaturesPresenter {
    weak var view: IExperimentalFeaturesView?

    private let router: IExperimentalFeaturesRouter
    private let interactor: IExperimentalFeaturesInteractor

    init(router: IExperimentalFeaturesRouter, interactor: IExperimentalFeaturesInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension ExperimentalFeaturesPresenter: IExperimentalFeaturesPresenter {

}

extension ExperimentalFeaturesPresenter: IExperimentalFeaturesInteractorDelegate {

}

extension ExperimentalFeaturesPresenter: IExperimentalFeaturesViewDelegate {

    func didTapBitcoinHodling() {

    }

}