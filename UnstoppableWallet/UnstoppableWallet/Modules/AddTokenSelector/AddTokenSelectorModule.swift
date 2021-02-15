protocol IAddTokenSelectorViewDelegate {
    func onTapErc20()
    func onTapBep20()
    func onTapBep2()
    func onTapClose()
}

protocol IAddTokenSelectorRouter {
    func closeAndShowAddErc20Token()
    func closeAndShowAddBep20Token()
    func closeAndShowAddBep2Token()
    func close()
}
