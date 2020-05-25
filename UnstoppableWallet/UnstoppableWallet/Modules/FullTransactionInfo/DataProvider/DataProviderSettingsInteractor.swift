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

    func providers(for coin: Coin) -> [IProvider] {
        return dataProviderManager.providers(for: coin)
    }

    func baseProvider(for coin: Coin) -> IProvider {
        return dataProviderManager.baseProvider(for: coin)
    }

    func setBaseProvider(name: String, for coin: Coin) {
        dataProviderManager.setBaseProvider(name: name, for: coin)
        delegate?.didSetBaseProvider()
    }

}
