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

//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
//            self?.delegate?.didReceiveTransactionInfo(record: FullTransactionRecord(resource: "test_record", url: transactionHash, sections: [
//                FullTransactionSection(title: nil, items: [
//                    FullTransactionItem(title: "ID", value: "6ce1832c7ko0324234kljfsdflsdj", clickable: true, url: nil, showExtra: .hash),
//                ]
//                ),
//                FullTransactionSection(title: nil, items: [
//                    FullTransactionItem(title: "Time", value: "2018-11-30 04:48:12", clickable: false, url: nil, showExtra: .none),
//                    FullTransactionItem(title: "Block", value: "#552001", clickable: false, url: nil, showExtra: .none),
//                    FullTransactionItem(title: "Confirmations", value: "#552001", clickable: false, url: nil, showExtra: .none)
//                ]
//                ),
//                FullTransactionSection(title: nil, items: [
//                    FullTransactionItem(title: "Total Input", value: "0.09683589 BTC", clickable: false, url: nil, showExtra: .none),
//                    FullTransactionItem(title: "Total Output", value: "0.09672645 BTC", clickable: false, url: nil, showExtra: .none),
//                    FullTransactionItem(title: "Size", value: "225 (bytes)", clickable: false, url: nil, showExtra: .none),
//                    FullTransactionItem(title: "Fee", value: "0.00010944 BTC", clickable: false, url: nil, showExtra: .none),
//                    FullTransactionItem(title: "Fee per byte", value: "48.64 sat/B", clickable: false, url: nil, showExtra: .none)
//                ]
//                ),
//                FullTransactionSection(title: "Inputs", items: [
//                    FullTransactionItem(title: "0.09683589 BTC", value: "1FABY8549JSK4378ers", clickable: true, url: nil, showExtra: .icon),
//                ]
//                ),
//                FullTransactionSection(title: "Outputs", items: [
//                    FullTransactionItem(title: "0.09672645 BTC", value: "1Adfdkjh4391FABY8549JSK4378ebty", clickable: true, url: nil, showExtra: .icon),
//                    FullTransactionItem(title: "0.09672645 BTC", value: "3Asdkhasudkh438kjfbs8FKJghdskshf", clickable: true, url: nil, showExtra: .icon)
//                ]
//                )
//            ]))
//        }
