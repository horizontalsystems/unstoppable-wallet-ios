import Alamofire
import RxSwift

class FullTransactionInfoProvider {
    private let disposeBag = DisposeBag()

    private let apiManager: IJSONApiManager
    private let adapter: IFullTransactionInfoAdapter
    private let async: Bool

    init(apiManager: IJSONApiManager, adapter: IFullTransactionInfoAdapter, async: Bool = true) {
        self.apiManager = apiManager
        self.adapter = adapter

        self.async = async
    }

}

extension FullTransactionInfoProvider: IFullTransactionInfoProvider {

    var providerName: String { return adapter.providerName }
    func url(for hash: String) -> String { return adapter.url(for: hash) }

    func retrieveTransactionInfo(transactionHash: String) -> Observable<FullTransactionRecord?> {
        var observable = apiManager.getJSON(url: adapter.apiUrl(for: transactionHash), parameters: nil)

        if async {
            observable = observable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        return observable.map { [weak self] jsonObject in
            return self?.adapter.convert(json: jsonObject)
        }
    }

}
