protocol IAddErc20TokenView: class {
    func set(address: String?, error: Error?)
    func set(spinnerVisible: Bool)
    func set(viewItem: AddErc20TokenModule.ViewItem?)
    func set(warningVisible: Bool)
    func set(buttonVisible: Bool)
    func refresh()
}

protocol IAddErc20TokenViewDelegate {
    func onTapPasteAddress()
    func onTapDeleteAddress()
    func onTapAddButton()
    func onTapCancel()
}

protocol IAddErc20TokenInteractor {
}

protocol IAddErc20TokenInteractorDelegate: AnyObject {
}

protocol IAddErc20TokenRouter {
    func close()
}

class AddErc20TokenModule {

    struct ViewItem {
        let coinName: String
        let symbol: String
        let decimals: Int
    }

}
