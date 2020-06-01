protocol IAddTokenViewDelegate {
    func onTapErc20()
    func onTapClose()
}

protocol IAddTokenRouter {
    func closeAndShowAddErc20Token()
    func close()
}
