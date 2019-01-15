import RxSwift

class FullTransactionInfoInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IFullTransactionInfoInteractorDelegate?

    private let transactionProvider: IFullTransactionInfoProvider
    private let reachabilityManager: IReachabilityManager
    private let pasteboardManager: IPasteboardManager

    private let async: Bool

    init(transactionProvider: IFullTransactionInfoProvider, reachabilityManager: IReachabilityManager, pasteboardManager: IPasteboardManager, async: Bool = true) {
        self.transactionProvider = transactionProvider
        self.reachabilityManager = reachabilityManager
        self.pasteboardManager = pasteboardManager

        self.async = async
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
    }

    func retrieveTransactionInfo(transactionHash: String) {
        transactionProvider.retrieveTransactionInfo(transactionHash: transactionHash).subscribe(onNext: { [weak self] record in
            if let record = record {
                self?.delegate?.didReceive(transactionRecord: record)
            } else {
                self?.delegate?.onError(providerName: self?.transactionProvider.providerName)
            }
        }, onError: { [weak self] _ in
            self?.delegate?.onError(providerName: self?.transactionProvider.providerName)
        }).disposed(by: disposeBag)
    }

    func url(for hash: String) -> String {
        return transactionProvider.url(for: hash)
    }

    func copyToPasteboard(value: String) {
        pasteboardManager.set(value: value)
    }

}