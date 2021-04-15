import Foundation
import RxSwift
import RxRelay
import RxCocoa

class MarkdownViewModel {
    private let service: MarkdownService
    private let parser: MarkdownParser
    private let disposeBag = DisposeBag()

    private var fontSize: Int = 17

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let viewItemsRelay = BehaviorRelay<[MarkdownBlockViewItem]?>(value: nil)
    private let openUrlRelay = PublishRelay<URL>()

    init(service: MarkdownService, parser: MarkdownParser) {
        self.service = service
        self.parser = parser

        sync(content: service.content)

        service.contentObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] content in
                    self?.sync(content: content)
                })
                .disposed(by: disposeBag)
    }

    private func sync(content: String?) {
        loadingRelay.accept(content == nil)

        viewItemsRelay.accept(content.map { parser.viewItems(content: $0, url: service.markdownUrl, fontSize: fontSize) })
    }

}

extension MarkdownViewModel {

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var viewItemsDriver: Driver<[MarkdownBlockViewItem]?> {
        viewItemsRelay.asDriver()
    }

    var openUrlSignal: Signal<URL> {
        openUrlRelay.asSignal()
    }

    func onTap(url: URL) {
        guard let resolvedUrl = URL(string: url.absoluteString, relativeTo: service.markdownUrl) else {
            return
        }

        openUrlRelay.accept(resolvedUrl)
    }

}
