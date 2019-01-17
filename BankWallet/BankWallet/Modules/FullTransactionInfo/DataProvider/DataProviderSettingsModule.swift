struct DataProviderItem: Equatable {
    let name: String
    let online: Bool
    let selected: Bool

    static func ==(lhs: DataProviderItem, rhs: DataProviderItem) -> Bool {
        return lhs.name == rhs.name
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
    func providers(for coinCode: String) -> [IProvider]
    func baseProvider(for coinCode: String) -> IProvider
    func setBaseProvider(name: String, for coinCode: String)
}

protocol IDataProviderSettingsInteractorDelegate: class {
    func didSetBaseProvider()
}

protocol IDataProviderSettingsRouter {
}
