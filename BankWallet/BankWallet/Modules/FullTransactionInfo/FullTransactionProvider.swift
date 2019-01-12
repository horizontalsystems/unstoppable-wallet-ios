import Foundation
import Alamofire
import RxSwift

class FullTransactionProvider {
    private let disposeBag = DisposeBag()

    private let apiManager: IJSONApiManager
    private let adapter: IFullTransactionInfoAdapter
    private let async: Bool

    private let _providerName: String
    private let _apiUrl: String
    private let _url: String

    init(apiManager: IJSONApiManager, adapter: IFullTransactionInfoAdapter, providerName: String, apiUrl: String, url: String, async: Bool = true) {
        self.apiManager = apiManager
        self.adapter = adapter

        self._providerName = providerName
        self._apiUrl = apiUrl
        self._url = url
        self.async = async
    }

}

extension FullTransactionProvider: IFullTransactionInfoProvider {
    var providerName: String { return _providerName }
    var url: String { return _url }

    func retrieveTransactionInfo(transactionHash: String) -> Observable<FullTransactionRecord?> {
        var observable = apiManager.getJSON(url: _apiUrl + transactionHash, parameters: nil)

        if async {
            observable = observable.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).observeOn(MainScheduler.instance)
        }

        return observable.map { [weak self] jsonObject in
            return self?.adapter.convert(json: jsonObject)
        }
    }

}
