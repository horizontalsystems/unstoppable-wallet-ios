import Foundation
import RxSwift
import RxCocoa
import MarketKit

class MarketAdvancedSearchViewModel {
    private let disposeBag = DisposeBag()

    private let service: MarketAdvancedSearchService

    private let buttonStateRelay = BehaviorRelay<ButtonState>(value: .loading)

    private let coinListViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let marketCapViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let volumeViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let priceChangeTypeViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let priceChangeViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let outperformedBtcRelay = BehaviorRelay<Bool>(value: false)
    private let outperformedEthRelay = BehaviorRelay<Bool>(value: false)
    private let outperformedBnbRelay = BehaviorRelay<Bool>(value: false)
    private let priceCloseToAthRelay = BehaviorRelay<Bool>(value: false)
    private let priceCloseToAtlRelay = BehaviorRelay<Bool>(value: false)

    init(service: MarketAdvancedSearchService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        subscribe(disposeBag, service.coinListObservable) { [weak self] in self?.sync(coinList: $0) }
        subscribe(disposeBag, service.marketCapObservable) { [weak self] in self?.sync(marketCap: $0) }
        subscribe(disposeBag, service.volumeObservable) { [weak self] in self?.sync(volume: $0) }
        subscribe(disposeBag, service.priceChangeTypeObservable) { [weak self] in self?.sync(priceChangeType: $0) }
        subscribe(disposeBag, service.priceChangeObservable) { [weak self] in self?.sync(priceChange: $0) }
        subscribe(disposeBag, service.outperformedBtcObservable) { [weak self] in self?.sync(outperformedBtc: $0) }
        subscribe(disposeBag, service.outperformedEthObservable) { [weak self] in self?.sync(outperformedEth: $0) }
        subscribe(disposeBag, service.outperformedBnbObservable) { [weak self] in self?.sync(outperformedBnb: $0) }
        subscribe(disposeBag, service.priceCloseToAthObservable) { [weak self] in self?.sync(priceCloseToAth: $0) }
        subscribe(disposeBag, service.priceCloseToAtlObservable) { [weak self] in self?.sync(priceCloseToAtl: $0) }

        sync(coinList: service.coinListCount)
        sync(marketCap: service.marketCap)
        sync(volume: service.volume)
        sync(priceChangeType: service.priceChangeType)
        sync(priceChange: service.priceChange)

        sync(state: service.state)
    }

    private func sync(state: MarketAdvancedSearchService.State) {
        switch state {
        case .loading:
            buttonStateRelay.accept(.loading)
        case .loaded(let marketInfos):
            if marketInfos.isEmpty {
                buttonStateRelay.accept(.emptyResults)
            } else {
                buttonStateRelay.accept(.showResults(count: marketInfos.count))
            }
        case .failed:
            buttonStateRelay.accept(.error("error"))
        }
    }

    private func sync(coinList: MarketAdvancedSearchService.CoinListCount) {
        coinListViewItemRelay.accept(ViewItem(value: service.coinListCount.title, valueStyle: .normal))
    }

    private func sync(marketCap: MarketAdvancedSearchService.ValueFilter) {
        marketCapViewItemRelay.accept(ViewItem(value: service.marketCap.title, valueStyle: service.marketCap.valueStyle))
    }

    private func sync(volume: MarketAdvancedSearchService.ValueFilter) {
        volumeViewItemRelay.accept(ViewItem(value: service.volume.title, valueStyle: service.volume.valueStyle))
    }

    private func sync(priceChangeType: MarketModule.PriceChangeType) {
        priceChangeTypeViewItemRelay.accept(ViewItem(value: service.priceChangeType.title, valueStyle: .normal))
    }

    private func sync(priceChange: MarketAdvancedSearchService.PriceChangeFilter) {
        priceChangeViewItemRelay.accept(ViewItem(value: service.priceChange.title, valueStyle: service.priceChange.valueStyle))
    }

    private func sync(outperformedBtc: Bool) {
        outperformedBtcRelay.accept(outperformedBtc)
    }

    private func sync(outperformedEth: Bool) {
        outperformedEthRelay.accept(outperformedEth)
    }

    private func sync(outperformedBnb: Bool) {
        outperformedBnbRelay.accept(outperformedBnb)
    }

    private func sync(priceCloseToAth: Bool) {
        priceCloseToAthRelay.accept(priceCloseToAth)
    }

    private func sync(priceCloseToAtl: Bool) {
        priceCloseToAtlRelay.accept(priceCloseToAtl)
    }

}

extension MarketAdvancedSearchViewModel {

    var buttonStateDriver: Driver<ButtonState> {
        buttonStateRelay.asDriver()
    }

    var coinListViewItemDriver: Driver<ViewItem> {
        coinListViewItemRelay.asDriver()
    }

    var marketCapViewItemDriver: Driver<ViewItem> {
        marketCapViewItemRelay.asDriver()
    }

    var volumeViewItemDriver: Driver<ViewItem> {
        volumeViewItemRelay.asDriver()
    }

    var priceChangeTypeViewItemDriver: Driver<ViewItem> {
        priceChangeTypeViewItemRelay.asDriver()
    }

    var priceChangeViewItemDriver: Driver<ViewItem> {
        priceChangeViewItemRelay.asDriver()
    }

    var outperformedBtcDriver: Driver<Bool> {
        outperformedBtcRelay.asDriver()
    }

    var outperformedEthDriver: Driver<Bool> {
        outperformedEthRelay.asDriver()
    }

    var outperformedBnbDriver: Driver<Bool> {
        outperformedBnbRelay.asDriver()
    }

    var priceCloseToATHDriver: Driver<Bool> {
        priceCloseToAthRelay.asDriver()
    }

    var priceCloseToATLDriver: Driver<Bool> {
        priceCloseToAtlRelay.asDriver()
    }

    var coinListViewItems: [FilterViewItem] {
        MarketAdvancedSearchService.CoinListCount.allCases.map {
            FilterViewItem(title: $0.title, style: .normal, selected: service.coinListCount == $0)
        }
    }

    var marketCapViewItems: [FilterViewItem] {
        MarketAdvancedSearchService.ValueFilter.allCases.map {
            FilterViewItem(title: $0.title, style: $0.valueStyle, selected: service.marketCap == $0)
        }
    }

    var volumeViewItems: [FilterViewItem] {
        MarketAdvancedSearchService.ValueFilter.allCases.map {
            FilterViewItem(title: $0.title, style: $0.valueStyle, selected: service.volume == $0)
        }
    }

    var priceChangeTypeViewItems: [FilterViewItem] {
        MarketModule.PriceChangeType.allCases.map {
            FilterViewItem(title: $0.title, style: .normal, selected: service.priceChangeType == $0)
        }
    }

    var priceChangeViewItems: [FilterViewItem] {
        MarketAdvancedSearchService.PriceChangeFilter.allCases.map {
            FilterViewItem(title: $0.title, style: $0.valueStyle, selected: service.priceChange == $0)
        }
    }

    var marketInfos: [MarketInfo] {
        guard case .loaded(let marketInfos) = service.state else {
            return []
        }

        return marketInfos
    }

    var priceChangeType: MarketModule.PriceChangeType {
        service.priceChangeType
    }

    func setCoinList(at index: Int) {
        service.coinListCount = MarketAdvancedSearchService.CoinListCount.allCases[index]
    }

    func setMarketCap(at index: Int) {
        service.marketCap = MarketAdvancedSearchService.ValueFilter.allCases[index]
    }

    func setVolume(at index: Int) {
        service.volume = MarketAdvancedSearchService.ValueFilter.allCases[index]
    }

    func setPriceChangeType(at index: Int) {
        service.priceChangeType = MarketModule.PriceChangeType.allCases[index]
    }

    func setPriceChange(at index: Int) {
        service.priceChange = MarketAdvancedSearchService.PriceChangeFilter.allCases[index]
    }

    func setOutperformedBtc(isOn: Bool) {
        service.outperformedBtc = isOn
    }

    func setOutperformedEth(isOn: Bool) {
        service.outperformedEth = isOn
    }

    func setOutperformedBnb(isOn: Bool) {
        service.outperformedBnb = isOn
    }

    func setPriceCloseToATH(isOn: Bool) {
        service.priceCloseToAth = isOn
    }

    func setPriceCloseToATL(isOn: Bool) {
        service.priceCloseToAtl = isOn
    }

    func reset() {
        service.reset()
    }

}

extension MarketAdvancedSearchViewModel {

    struct FilterViewItem {
        let title: String
        let style: ValueStyle
        let selected: Bool
    }

    enum ValueStyle {
        case normal
        case positive
        case negative
        case none
    }

    struct ViewItem {
        let value: String
        let valueStyle: ValueStyle
    }

    enum ButtonState {
        case loading
        case emptyResults
        case showResults(count: Int)
        case error(String)
    }

}

extension MarketAdvancedSearchService.CoinListCount {

    var title: String {
        "market.advanced_search.top".localized(self.rawValue)
    }

}

extension MarketAdvancedSearchService.ValueFilter {

    var title: String {
        switch self {
        case .none: return "market.advanced_search.any".localized
        case .lessM5: return "market.advanced_search.less_5_m".localized
        case .m5m20: return "market.advanced_search.m_5_m_20".localized
        case .m20m100: return "market.advanced_search.m_20_m_100".localized
        case .m100b1: return "market.advanced_search.m_100_b_1".localized
        case .b1b5: return "market.advanced_search.b_1_b_5".localized
        case .moreB5: return "market.advanced_search.more_5_b".localized
        }
    }

    var valueStyle: MarketAdvancedSearchViewModel.ValueStyle {
        self == .none ? .none : .normal
    }

}

extension MarketAdvancedSearchService.PriceChangeFilter {

    var title: String {
        switch self {
        case .none: return "market.advanced_search.any".localized
        case .plus10: return "> +10 %"
        case .plus25: return "> +25 %"
        case .plus50: return "> +50 %"
        case .plus100: return "> +100 %"
        case .minus10: return "< -10 %"
        case .minus25: return "< -25 %"
        case .minus50: return "< -50 %"
        case .minus100: return "< -100 %"
        }
    }

    var valueStyle: MarketAdvancedSearchViewModel.ValueStyle {
        switch self {
        case .none: return .none
        case .plus10, .plus25, .plus50, .plus100: return .positive
        case .minus10, .minus25, .minus50, .minus100: return .negative
        }
    }

}
