import RxSwift

class FullTransactionInfoInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IFullTransactionInfoInteractorDelegate?

    private let transactionProvider: IFullTransactionInfoProvider
    private let reachabilityManager: IReachabilityManager
    private let pasteboardManager: IPasteboardManager

    init(transactionProvider: IFullTransactionInfoProvider, reachabilityManager: IReachabilityManager, pasteboardManager: IPasteboardManager) {
        self.transactionProvider = transactionProvider
        self.reachabilityManager = reachabilityManager
        self.pasteboardManager = pasteboardManager

        reachabilityManager.reachabilitySignal
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentMainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.retryLoadInfo()
                })
                .disposed(by: disposeBag)

    }

}

extension FullTransactionInfoInteractor: IFullTransactionInfoInteractor {

    func retryLoadInfo() {
        if reachabilityManager.isReachable {
            delegate?.retryLoadInfo()
        }
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

    func onTap(item: FullTransactionItem) {
        guard item.clickable else {
            return
        }

        if let url = item.url {
            delegate?.onOpen(url: url)
        }

        if let value = item.value {
            pasteboardManager.set(value: value)
            delegate?.onCopied()
        }
    }

}