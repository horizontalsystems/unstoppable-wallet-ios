import RxSwift

class FullTransactionInfoInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IFullTransactionInfoInteractorDelegate?

    private let providerFactory: IFullTransactionInfoProviderFactory
    private var provider: IFullTransactionInfoProvider?

    private let reachabilityManager: IReachabilityManager
    private let dataProviderManager: IFullTransactionDataProviderManager
    private let pasteboardManager: IPasteboardManager

    private let async: Bool

    init(providerFactory: IFullTransactionInfoProviderFactory, reachabilityManager: IReachabilityManager, dataProviderManager: IFullTransactionDataProviderManager, pasteboardManager: IPasteboardManager, async: Bool = true) {
        self.providerFactory = providerFactory
        self.reachabilityManager = reachabilityManager
        self.dataProviderManager = dataProviderManager
        self.pasteboardManager = pasteboardManager

        self.async = async
    }

    private func showError() {
        delegate?.onTransactionNotFound(providerName: provider?.providerName)
    }

    private func showOffline() {
        delegate?.onProviderOffline(providerName: provider?.providerName)
    }

}

extension FullTransactionInfoInteractor: IFullTransactionInfoInteractor {

    var reachableConnection: Bool { return reachabilityManager.isReachable }

    func didLoad() {
        //  Reachability Manager Signal
        var reachabilitySignal: Observable = reachabilityManager.reachabilitySignal.asObserver()

        if async {
            reachabilitySignal = reachabilitySignal.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        reachabilitySignal.subscribe(onNext: { [weak self] in
            self?.delegate?.onConnectionChanged()
        }).disposed(by: disposeBag)

        //  DataProvider Manager Signal
        var dataProviderUpdatedSignal: Observable = dataProviderManager.dataProviderUpdatedSignal.asObserver()

        if async {
            dataProviderUpdatedSignal = dataProviderUpdatedSignal.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        dataProviderUpdatedSignal.subscribe(onNext: { [weak self] in
            self?.delegate?.onProviderChanged()
        }).disposed(by: disposeBag)
    }

    func updateProvider(for wallet: Wallet) {
        provider = providerFactory.provider(for: wallet)
    }

    func retrieveTransactionInfo(transactionHash: String) {
        provider?.retrieveTransactionInfo(transactionHash: transactionHash).subscribe(onSuccess: { [weak self] record in
            if let record = record {
                self?.delegate?.didReceive(transactionRecord: record)
            } else {
                self?.showError()
            }
        }, onError: { [weak self] error in
            if let error = error as? NetworkManager.NetworkError, case .noConnection = error {
                self?.showOffline()
            } else {
                self?.showError()
            }
        }).disposed(by: disposeBag)
    }

    func url(for hash: String) -> String? {
        provider?.url(for: hash)
    }

    func copyToPasteboard(value: String) {
        pasteboardManager.set(value: value)
    }

}