import RxSwift
class DataProviderSettingsInteractor {
    private static let timeoutInterval: TimeInterval = 8.0
    private let disposeBag = DisposeBag()

    weak var delegate: IDataProviderSettingsInteractorDelegate?

    private let dataProviderManager: IFullTransactionDataProviderManager
    private let pingManager: IPingManager
    private let async: Bool

    init(dataProviderManager: IFullTransactionDataProviderManager, pingManager: IPingManager, async: Bool = true) {
        self.dataProviderManager = dataProviderManager
        self.pingManager = pingManager
        self.async = async
    }

}

extension DataProviderSettingsInteractor: IDataProviderSettingsInteractor {

    func pingProvider(name: String, url: String) {
        var observable = pingManager.serverAvailable(url: url, timeoutInterval: DataProviderSettingsInteractor.timeoutInterval)

        if async {
            observable = observable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        observable.subscribe(onNext: { [weak self] interval in
            self?.delegate?.didPingSuccess(name: name, timeInterval: interval)
        }, onError: { [weak self] error in
            self?.delegate?.didPingFailure(name: name)
        }).disposed(by: disposeBag)
    }

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
