import Foundation
import RxSwift
import RxRelay
import RxCocoa
import Down

class MarkdownViewModel {
    private let service: MarkdownService
    private let parser: MarkdownParser
    private let parserConfig: DownStylerConfiguration
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let viewItemsRelay = BehaviorRelay<[MarkdownBlockViewItem]?>(value: nil)
    private let openUrlRelay = PublishRelay<URL>()

    init(service: MarkdownService, parser: MarkdownParser, parserConfig: DownStylerConfiguration) {
        self.service = service
        self.parser = parser
        self.parserConfig = parserConfig

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

        viewItemsRelay.accept(content.map { parser.viewItems(content: $0, url: service.markdownUrl, configuration: parserConfig) })
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
