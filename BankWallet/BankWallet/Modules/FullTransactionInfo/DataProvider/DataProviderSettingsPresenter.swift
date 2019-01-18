class DataProviderSettingsPresenter {
    private let coinCode: String

    private let router: IDataProviderSettingsRouter
    private let interactor: IDataProviderSettingsInteractor

    weak var view: IDataProviderSettingsView?

    init(coinCode: String, router: IDataProviderSettingsRouter, interactor: IDataProviderSettingsInteractor) {
        self.coinCode = coinCode
        self.router = router
        self.interactor = interactor
    }

    private func showItems() {
        let baseProviderName = interactor.baseProvider(for: coinCode).name

        view?.show(items: interactor.providers(for: coinCode).map { provider in
            DataProviderItem(name: provider.name, online: true, selected: provider.name == baseProviderName)
        })
    }

}

extension DataProviderSettingsPresenter: IDataProviderSettingsViewDelegate {

    func viewDidLoad() {
        showItems()
    }

    func didSelect(item: DataProviderItem) {
        if !item.selected {
            interactor.setBaseProvider(name: item.name, for: coinCode)
        }
    }

}

extension DataProviderSettingsPresenter: IDataProviderSettingsInteractorDelegate {

    func didSetBaseProvider() {
        showItems()
        router.popViewController()
    }

}
