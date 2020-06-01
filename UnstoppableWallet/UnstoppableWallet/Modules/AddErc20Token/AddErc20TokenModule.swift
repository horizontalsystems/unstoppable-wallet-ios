protocol IAddErc20TokenView: class {
}

protocol IAddErc20TokenViewDelegate {
    func onTapCancel()
}

protocol IAddErc20TokenInteractor {
}

protocol IAddErc20TokenInteractorDelegate: AnyObject {
}

protocol IAddErc20TokenRouter {
    func close()
}
