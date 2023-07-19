import RxSwift
import RxRelay
import HsToolKit

class FaqRepository {
    private let disposeBag = DisposeBag()

    private let networkManager: NetworkManager
    private let reachabilityManager: IReachabilityManager

    private let faqRelay = BehaviorRelay<DataStatus<[FaqSection]>>(value: .loading)

    init(networkManager: NetworkManager, reachabilityManager: IReachabilityManager) {
        self.networkManager = networkManager
        self.reachabilityManager = reachabilityManager

        reachabilityManager.reachabilityObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] reachable in
                    if reachable {
                        self?.onReachable()
                    }
                })
                .disposed(by: disposeBag)

        fetch()
    }

    private func onReachable() {
        if case .failed = faqRelay.value {
            fetch()
        }
    }

    private func fetch() {
        faqRelay.accept(.loading)

        let request = networkManager.session.request(AppConfig.faqIndexUrl)

        networkManager.single(request: request, mapper: self)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] faq in
                    self?.faqRelay.accept(.completed(faq))
                }, onError: { [weak self] error in
                    self?.faqRelay.accept(.failed(error))
                })
                .disposed(by: disposeBag)
    }

}

extension FaqRepository {

    var faqObservable: Observable<DataStatus<[FaqSection]>> {
        faqRelay.asObservable()
    }

}

extension FaqRepository: IApiMapper {

    public func map(statusCode: Int, data: Any?) throws -> [FaqSection] {
        guard let array = data as? [[String: Any]] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        var sections = [FaqSection]()

        for sectionJson in array {
            guard let titles = sectionJson["section"] as? [String: String] else {
                continue
            }

            guard let itemsJson = sectionJson["items"] as? [[String: Any]] else {
                continue
            }

            let items = try itemsJson.map { languageMap in
                try languageMap.mapValues { faqJson in
                    try Faq(JSONObject: faqJson)
                }
            }

            sections.append(FaqSection(titles: titles, items: items))
        }

        return sections
    }

}
