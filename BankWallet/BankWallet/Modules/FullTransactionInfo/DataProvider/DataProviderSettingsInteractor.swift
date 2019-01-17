class DataProviderSettingsInteractor {
    weak var delegate: IDataProviderSettingsInteractorDelegate?

    private let dataProviderManager: IFullTransactionDataProviderManager

    init(dataProviderManager: IFullTransactionDataProviderManager) {
        self.dataProviderManager = dataProviderManager
    }

}

extension DataProviderSettingsInteractor: IDataProviderSettingsInteractor {

    func providers(for coinCode: String) -> [IProvider] {
        return dataProviderManager.providers(for: coinCode)
    }

    func baseProvider(for coinCode: String) -> IProvider {
        return dataProviderManager.baseProvider(for: coinCode)
    }

    func setBaseProvider(name: String, for coinCode: String) {
        dataProviderManager.setBaseProvider(name: name, for: coinCode)
        delegate?.didSetBaseProvider()
    }

}
