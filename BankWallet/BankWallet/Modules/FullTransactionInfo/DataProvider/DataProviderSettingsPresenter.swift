class DataProviderSettingsPresenter {
    private let coinCode: String
    private let transactionHash: String

    private let router: IDataProviderSettingsRouter
    private let interactor: IDataProviderSettingsInteractor

    weak var view: IDataProviderSettingsView?

    var items = [DataProviderItem]()

    init(coinCode: String, transactionHash: String, router: IDataProviderSettingsRouter, interactor: IDataProviderSettingsInteractor) {
        self.coinCode = coinCode
        self.transactionHash = transactionHash
        self.router = router
        self.interactor = interactor
    }

}

extension DataProviderSettingsPresenter: IDataProviderSettingsViewDelegate {

    func viewDidLoad() {
        let baseProviderName = interactor.baseProvider(for: coinCode).name

        let providers = interactor.providers(for: coinCode)
        providers.forEach { provider in
            interactor.pingProvider(name: provider.name, url: provider.apiUrl(for: transactionHash))
        }

        items = providers.map { provider in
            DataProviderItem(name: provider.name, online: true, checking: true, selected: provider.name == baseProviderName)
        }

        view?.show(items: items)
    }

    func didSelect(item: DataProviderItem) {
        if !item.selected {
            interactor.setBaseProvider(name: item.name, for: coinCode)
        }
    }

}

extension DataProviderSettingsPresenter: IDataProviderSettingsInteractorDelegate {

    func didPingSuccess(name: String, timeInterval: Double) {
        setStateForItem(name: name, online: true)
    }

    func didPingFailure(name: String) {
        setStateForItem(name: name, online: false)
    }

    private func setStateForItem(name: String, online: Bool) {
        let baseProviderName = interactor.baseProvider(for: coinCode).name

        let item = DataProviderItem(name: name, online: online, checking: false, selected: name == baseProviderName)
        if let index = items.firstIndex(where: { $0.name == name }) {
            items[index] = item
            view?.show(items: items)
        }
    }

    func didSetBaseProvider() {
        router.popViewController()
    }

}
