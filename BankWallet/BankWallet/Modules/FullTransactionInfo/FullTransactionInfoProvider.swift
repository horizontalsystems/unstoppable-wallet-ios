import Alamofire
import RxSwift
import HsToolKit

class FullTransactionInfoProvider {
    private let disposeBag = DisposeBag()

    private let networkManager: NetworkManager
    private let adapter: IFullTransactionInfoAdapter
    private let provider: IProvider

    init(networkManager: NetworkManager, adapter: IFullTransactionInfoAdapter, provider: IProvider) {
        self.networkManager = networkManager
        self.adapter = adapter
        self.provider = provider
    }

}

extension FullTransactionInfoProvider: IFullTransactionInfoProvider {

    var providerName: String {
        provider.name
    }

    func url(for hash: String) -> String? {
        provider.url(for: hash)
    }

    func retrieveTransactionInfo(transactionHash: String) -> Single<FullTransactionRecord?> {
        let request = provider.request(session: networkManager.session, hash: transactionHash)

        return networkManager.single(request: request, mapper: self)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .map { [weak self] json in
                    self?.adapter.convert(json: json)
                }
    }

}

extension FullTransactionInfoProvider: IApiMapper {

    public func map(statusCode: Int, data: Any?) throws -> [String: Any] {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return map
    }

}
