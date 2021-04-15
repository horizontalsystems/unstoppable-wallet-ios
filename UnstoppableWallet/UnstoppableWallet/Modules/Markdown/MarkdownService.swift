import Foundation
import RxSwift
import RxRelay
import HsToolKit
import Alamofire

class MarkdownService {
    private let provider: IMarkdownContentProvider
    private let disposeBag = DisposeBag()

    private let contentRelay = PublishRelay<String?>()
    private(set) var content: String? {
        didSet {
            contentRelay.accept(content)
        }
    }

    init(provider: IMarkdownContentProvider) {
        self.provider = provider

        fetchContent()
    }

    private func fetchContent() {
        provider.contentSingle
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] content in
                    self?.content = content
                })
                .disposed(by: disposeBag)
    }

}

extension MarkdownService {

    var contentObservable: Observable<String?> {
        contentRelay.asObservable()
    }

    var markdownUrl: URL? {
        provider.markdownUrl
    }

}
