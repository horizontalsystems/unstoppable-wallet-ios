import RxSwift
import RxCocoa

class MarketTickerViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketTickerService

    private let tickerDataRelay = BehaviorRelay<[MarketTickerViewModel.ViewItem]>(value: [])

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isLoading: Bool = false

    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private var error: String?

    init(service: MarketTickerService) {
        self.service = service

        subscribe(disposeBag, service.marketTickerDataObservable) { [weak self] in self?.sync(marketTickerData: $0) }
    }

    private func sync(marketTickerData: DataStatus<[MarketTickerService.Item]>) {
        if let data = marketTickerData.data {
            let headerViewItem = ViewItem(type: .header, text: "High Transaction Fee:")
            let viewItems = [headerViewItem] + data.flatMap { self.viewItems(for: $0) }
            tickerDataRelay.accept(viewItems)
        }
        isLoadingRelay.accept(marketTickerData.isLoading)
        errorRelay.accept(marketTickerData.error?.smartDescription)
    }

    private func viewItems(for item: MarketTickerService.Item) -> [ViewItem] {
        let title = "\(item.coin.code) - \(ValueFormatter.instance.format(currencyValue: item.currencyValue) ?? "n/a".localized)"
        let value = "\(item.timeInterval / 60) min | \(item.fee.description) sat/b"

        return [
            ViewItem(type: .title, text: title),
            ViewItem(type: .value, text: value),
        ]
    }

}

extension MarketTickerViewModel {

    var tickerDataDriver: Driver<[MarketTickerViewModel.ViewItem]> {
        tickerDataRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    public func refresh() {
        service.refresh()
    }

}

extension MarketTickerViewModel {

    enum ViewItemType {
        case header
        case title
        case value
    }

    struct ViewItem {
        let type: ViewItemType
        let text: String
    }

}
