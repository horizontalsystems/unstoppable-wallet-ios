protocol IAddTokenSelectorViewDelegate {
    func onTapErc20()
    func onTapBinance()
    func onTapClose()
}

protocol IAddTokenSelectorRouter {
    func closeAndShowAddErc20Token()
    func closeAndShowAddBinanceToken()
    func close()
}
