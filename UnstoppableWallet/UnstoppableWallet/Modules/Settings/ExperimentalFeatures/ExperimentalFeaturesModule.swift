protocol IExperimentalFeaturesRouter {
    func showBitcoinHodling()
}

protocol IExperimentalFeaturesViewDelegate: AnyObject {
    func didTapBitcoinHodling()
}
