protocol IExperimentalFeaturesRouter {
    func showBitcoinHodling()
}

protocol IExperimentalFeaturesPresenter {

}

protocol IExperimentalFeaturesInteractor {

}

protocol IExperimentalFeaturesView: class {

}

protocol IExperimentalFeaturesInteractorDelegate: class {

}

protocol IExperimentalFeaturesViewDelegate: class {
    func didTapBitcoinHodling()
}