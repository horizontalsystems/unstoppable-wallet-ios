import Foundation
import RxSwift

class FullTransactionInfoInteractor {
    private let disposeBag = DisposeBag()
    weak var delegate: IFullTransactionInfoInteractorDelegate?

    private var transactionProvider: IFullTransactionInfoProvider
    private let pasteboardManager: IPasteboardManager

    init(transactionProvider: IFullTransactionInfoProvider, pasteboardManager: IPasteboardManager) {
        self.transactionProvider = transactionProvider
        self.pasteboardManager = pasteboardManager
    }
}

extension FullTransactionInfoInteractor: IFullTransactionInfoInteractor {

    func retrieveTransactionInfo(transactionHash: String) {
        transactionProvider.retrieveTransactionInfo(transactionHash: transactionHash).subscribe(onNext: { [weak self] record in
            if let record = record {
                self?.delegate?.didReceive(transactionRecord: record)
            } else {
                self?.delegate?.onError()
            }
        }, onError: { [weak self] _ in
            self?.delegate?.onError()
        }).disposed(by: disposeBag)
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