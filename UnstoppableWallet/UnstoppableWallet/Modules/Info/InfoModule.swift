protocol IInfoRouter {
    func open(url: String)
    func close()
}

protocol IInfoViewDelegate {
    func onTapLink()
    func onTapClose()
}
