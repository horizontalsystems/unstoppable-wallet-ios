protocol IAddErc20TokenView: class {
    func set(error: Error?)
    func set(spinnerVisible: Bool)
    func set(viewItem: AddErc20TokenModule.ViewItem?)
    func set(warningVisible: Bool)
    func set(buttonVisible: Bool)
    func refresh()
    func showSuccess()
}

protocol IAddErc20TokenViewDelegate {
    func onChange(address: String?)
    func onTapAddButton()
    func onTapCancel()
}

protocol IAddErc20TokenInteractor {
    var valueFromPasteboard: String? { get }
    func validate(address: String) throws
    func existingCoin(address: String) -> Coin?
    func fetchCoin(address: String)
    func abortFetchingCoin()
    func save(coin: Coin)
}

protocol IAddErc20TokenInteractorDelegate: AnyObject {
    func didFetch(coin: Coin)
    func didFailToFetchCoin(error: Error)
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
