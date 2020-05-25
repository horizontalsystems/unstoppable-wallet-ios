protocol IExperimentalFeaturesRouter {
    func showBitcoinHodling()
}

protocol IExperimentalFeaturesViewDelegate: class {
    func didTapBitcoinHodling()
}
