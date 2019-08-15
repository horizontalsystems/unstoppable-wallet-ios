import Alamofire
import RxSwift

class FullTransactionInfoProvider {
    private let disposeBag = DisposeBag()

    private let apiProvider: IJsonApiProvider
    private let adapter: IFullTransactionInfoAdapter
    private let provider: IProvider
    private let async: Bool

    init(apiProvider: IJsonApiProvider, adapter: IFullTransactionInfoAdapter, provider: IProvider, async: Bool = true) {
        self.apiProvider = apiProvider
        self.adapter = adapter
        self.provider = provider

        self.async = async
    }

}

extension FullTransactionInfoProvider: IFullTransactionInfoProvider {

    var providerName: String { return provider.name }
    func url(for hash: String) -> String? { return provider.url(for: hash) }

    func retrieveTransactionInfo(transactionHash: String) -> Single<FullTransactionRecord?> {
        var single = apiProvider.getJson(requestObject: provider.requestObject(for: transactionHash))

        if async {
            single = single.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        return single.map { [weak self] jsonObject in
            self?.adapter.convert(json: jsonObject)
        }
    }

}
