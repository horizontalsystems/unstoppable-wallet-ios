struct DataProviderItem: Equatable {
    let name: String
    let online: Bool
    let checking: Bool
    let selected: Bool

    static func ==(lhs: DataProviderItem, rhs: DataProviderItem) -> Bool {
        return lhs.name == rhs.name && lhs.online == rhs.online && lhs.checking == rhs.checking
    }
}

protocol IDataProviderSettingsView: class {
    func show(items: [DataProviderItem])
}

protocol IDataProviderSettingsViewDelegate {
    func viewDidLoad()
    func didSelect(item: DataProviderItem)
}

protocol IDataProviderSettingsInteractor {
    func pingProvider(name: String, url: String)
    func providers(for coin: Coin) -> [IProvider]
    func baseProvider(for coin: Coin) -> IProvider
    func setBaseProvider(name: String, for coin: Coin)
}

protocol IDataProviderSettingsInteractorDelegate: class {
    func didSetBaseProvider()
    func didPingSuccess(name: String, timeInterval: Double)
    func didPingFailure(name: String)
}

protocol IDataProviderSettingsRouter {
    func popViewController()
}
