import RxSwift

class FullTransactionInfoInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IFullTransactionInfoInteractorDelegate?

    private let providerFactory: IFullTransactionInfoProviderFactory
    private var provider: IFullTransactionInfoProvider?

    private let reachabilityManager: IReachabilityManager
    private let pasteboardManager: IPasteboardManager

    private let async: Bool

    init(providerFactory: IFullTransactionInfoProviderFactory, reachabilityManager: IReachabilityManager, pasteboardManager: IPasteboardManager, async: Bool = true) {
        self.providerFactory = providerFactory
        self.reachabilityManager = reachabilityManager
        self.pasteboardManager = pasteboardManager

        self.async = async
    }

    private func showError() {
        delegate?.onError(providerName: provider?.providerName)
    }

}

extension FullTransactionInfoInteractor: IFullTransactionInfoInteractor {

    var reachableConnection: Bool { return reachabilityManager.isReachable }

    func didLoad() {
        var signal: Observable = reachabilityManager.reachabilitySignal.asObserver()

        if async {
            signal = signal.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        signal.subscribe(onNext: { [weak self] in
            self?.delegate?.onConnectionChanged()
        }).disposed(by: disposeBag)

        // changeProviderSignal.onNext() -> delegate.didLoadRestart()
    }

    func updateProvider(for coinCode: String) {
        provider = providerFactory.provider(for: coinCode)
    }

    func retrieveTransactionInfo(transactionHash: String) {
        provider?.retrieveTransactionInfo(transactionHash: transactionHash).subscribe(onNext: { [weak self] record in
            if let record = record {
                self?.delegate?.didReceive(transactionRecord: record)
            } else {
                self?.showError()
            }
        }, onError: { [weak self] _ in
            self?.showError()
        }).disposed(by: disposeBag)
    }

    func url(for hash: String) -> String? {
        return provider?.url(for: hash)
    }

    func copyToPasteboard(value: String) {
        pasteboardManager.set(value: value)
    }

}