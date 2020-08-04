protocol IUniswapInfoRouter {
    func open(url: String)
    func close()
}

protocol IUniswapInfoViewDelegate {
    func onTapLink()
    func onTapClose()
}
