protocol IAddErc20TokenView: class {
    func set(address: String?)
}

protocol IAddErc20TokenViewDelegate {
    func onTapPasteAddress()
    func onTapDeleteAddress()
    func onTapCancel()
}

protocol IAddErc20TokenInteractor {
}

protocol IAddErc20TokenInteractorDelegate: AnyObject {
}

protocol IAddErc20TokenRouter {
    func close()
}
