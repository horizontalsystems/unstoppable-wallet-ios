import Alamofire
import RxSwift

class FullTransactionInfoProvider {
    private let disposeBag = DisposeBag()

    private let apiManager: IJSONApiManager
    private let adapter: IFullTransactionInfoAdapter
    private let provider: IProvider
    private let async: Bool

    init(apiManager: IJSONApiManager, adapter: IFullTransactionInfoAdapter, provider: IProvider, async: Bool = true) {
        self.apiManager = apiManager
        self.adapter = adapter
        self.provider = provider

        self.async = async
    }

}

extension FullTransactionInfoProvider: IFullTransactionInfoProvider {

    var providerName: String { return provider.name }
    func url(for hash: String) -> String { return provider.url(for: hash) }

    func retrieveTransactionInfo(transactionHash: String) -> Observable<FullTransactionRecord?> {
        var observable = apiManager.getJSON(url: provider.apiUrl(for: transactionHash), parameters: nil)

        if async {
            observable = observable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        return observable.map { [weak self] jsonObject in
            return self?.adapter.convert(json: jsonObject)
        }
    }

}
