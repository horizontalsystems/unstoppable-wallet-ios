import Foundation
import RxSwift

class FullTransactionInfoInteractor {
    private let disposeBag = DisposeBag()

    private var transactionProvider: IFullTransactionInfoProvider
    weak var delegate: IFullTransactionInfoInteractorDelegate?

    init(transactionProvider: IFullTransactionInfoProvider) {
        self.transactionProvider = transactionProvider
    }
}

extension FullTransactionInfoInteractor: IFullTransactionInfoInteractor {

    func retrieveTransactionInfo(transactionHash: String) {
        transactionProvider.retrieveTransactionInfo(transactionHash: transactionHash).subscribe(onNext: { [weak self] record in
            if let record = record {
                self?.delegate?.didReceive(transactionRecord: record)
            } else {
                print("Nil")
            }
        }).disposed(by: disposeBag)
    }

}

//extension FullTransactionInfoInteractor: IFullTransactionInfoProviderDelegate {
//
//    func didReceiveTransactionInfo(record: FullTransactionRecord) {
//        delegate?.didReceive(transactionRecord: record)
//    }
//
//    func didReceiveError(error: Error) {
//        print("error \(error.localizedDescription)")
//    }
//
//}
