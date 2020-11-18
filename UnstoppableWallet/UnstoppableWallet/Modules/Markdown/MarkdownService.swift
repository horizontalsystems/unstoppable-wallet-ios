import Foundation
import RxSwift
import RxRelay
import HsToolKit
import Alamofire

class MarkdownService {
    let url: URL
    private let networkManager: NetworkManager
    private let disposeBag = DisposeBag()

    private let contentRelay = PublishRelay<String?>()
    private(set) var content: String? {
        didSet {
            contentRelay.accept(content)
        }
    }

    init(url: URL, networkManager: NetworkManager) {
        self.url = url
        self.networkManager = networkManager

        fetchContent()
    }

    private func fetchContent() {
        contentSingle(url: url)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] content in
                    self?.content = content
                })
                .disposed(by: disposeBag)
    }

    private func contentSingle(url: URL) -> Single<String> {
        let request = networkManager.session.request(url)

        return Single.create { observer in
            let requestReference = request.responseString(queue: DispatchQueue.global(qos: .background)) { response in
                switch response.result {
                case .success(let result):
                    observer(.success(result))
                case .failure(let error):
                    observer(.error(NetworkManager.unwrap(error: error)))
                }
            }

            return Disposables.create {
                requestReference.cancel()
            }
        }
    }

}

extension MarkdownService {

    var contentObservable: Observable<String?> {
        contentRelay.asObservable()
    }

}
