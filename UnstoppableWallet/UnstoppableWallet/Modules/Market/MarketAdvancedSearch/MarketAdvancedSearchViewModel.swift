import Foundation
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit

class MarketAdvancedSearchViewModel {
    private let disposeBag = DisposeBag()

    private let service: MarketAdvancedSearchService

    private let buttonStateRelay = BehaviorRelay<ButtonState>(value: .loading)

    private let coinListViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let marketCapViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let volumeViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let blockchainsViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let priceChangeTypeViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let priceChangeViewItemRelay = BehaviorRelay<ViewItem>(value: ViewItem(value: "", valueStyle: .none))
    private let outperformedBtcRelay = BehaviorRelay<Bool>(value: false)
    private let outperformedEthRelay = BehaviorRelay<Bool>(value: false)
    private let outperformedBnbRelay = BehaviorRelay<Bool>(value: false)
    private let priceCloseToAthRelay = BehaviorRelay<Bool>(value: false)
    private let priceCloseToAtlRelay = BehaviorRelay<Bool>(value: false)

    private var valueFilters: [MarketAdvancedSearchService.ValueFilter] {
        MarketAdvancedSearchService.ValueFilter.valuesByCurrencyCode[service.currencyCode] ?? []
    }

    init(service: MarketAdvancedSearchService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        subscribe(disposeBag, service.coinListObservable) { [weak self] in self?.sync(coinList: $0) }
        subscribe(disposeBag, service.marketCapObservable) { [weak self] in self?.sync(marketCap: $0) }
        subscribe(disposeBag, service.volumeObservable) { [weak self] in self?.sync(volume: $0) }
        subscribe(disposeBag, service.blockchainsObservable) { [weak self] in self?.sync(blockchains: $0) }
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
        sync(blockchains: service.blockchains)
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

    private func sync(blockchains: [Blockchain]) {
        let value: String
        let valueStyle: ValueStyle

        if service.blockchains.isEmpty {
            value = "market.advanced_search.any".localized
            valueStyle = .none
        } else if service.blockchains.count == 1 {
            value = service.blockchains[0].name
            valueStyle = .normal
        } else {
            value = "\(service.blockchains.count)"
            valueStyle = .normal
        }

        blockchainsViewItemRelay.accept(ViewItem(value: value, valueStyle: valueStyle))
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

    var blockchainsViewItemDriver: Driver<ViewItem> {
        blockchainsViewItemRelay.asDriver()
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
        valueFilters.map {
            FilterViewItem(title: $0.title, style: $0.valueStyle, selected: service.marketCap == $0)
        }
    }

    var volumeViewItems: [FilterViewItem] {
        valueFilters.map {
            FilterViewItem(title: $0.title, style: $0.valueStyle, selected: service.volume == $0)
        }
    }

    var blockchainViewItems: [MultiSelectorViewController.ViewItem] {
        service.allBlockchains.map { blockchain in
            MultiSelectorViewController.ViewItem(
                    value: blockchain.name,
                    selected: service.blockchains.contains(blockchain)
            )
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
        service.marketCap = valueFilters[index]
    }

    func setVolume(at index: Int) {
        service.volume = valueFilters[index]
    }

    func setBlockchains(indexes: [Int]) {
        service.blockchains = indexes.map { service.allBlockchains[$0] }
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

    static let valuesByCurrencyCode: [String: [Self]] = [
        "USD": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5],
        "EUR": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5],
        "GBP": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5],
        "JPY": [.none, .lessM500, .m500b2, .b2b10, .b10b100, .b100b500, .moreB500],
        "AUD": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5],
        "BRL": [.none, .lessM50, .m50m200, .m200b1, .b1b10, .b10b50, .moreB50],
        "CAD": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5],
        "CHF": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5],
        "CNY": [.none, .lessM50, .m50m200, .m200b1, .b1b10, .b10b50, .moreB50],
        "HKD": [.none, .lessM50, .m50m200, .m200b1, .b1b10, .b10b50, .moreB50],
        "ILS": [.none, .lessM10, .m10m40, .m40m200, .m200b2, .b2b10, .moreB10],
        "RUB": [.none, .lessM500, .m500b2, .b2b10, .b10b100, .b100b500, .moreB500],
        "SGD": [.none, .lessM5, .m5m20, .m20m100, .m100b1, .b1b5, .moreB5]
    ]

    var title: String {
        switch self {
        case .none: return "market.advanced_search.any".localized
        case .lessM5: return "market.advanced_search.less_5_m".localized
        case .lessM10: return "market.advanced_search.less_10_m".localized
        case .lessM50: return "market.advanced_search.less_50_m".localized
        case .lessM500: return "market.advanced_search.less_500_m".localized
        case .m5m20: return "market.advanced_search.m_5_m_20".localized
        case .m10m40: return "market.advanced_search.m_10_m_40".localized
        case .m40m200: return "market.advanced_search.m_40_m_200".localized
        case .m50m200: return "market.advanced_search.m_50_m_200".localized
        case .m20m100: return "market.advanced_search.m_20_m_100".localized
        case .m100b1: return "market.advanced_search.m_100_b_1".localized
        case .m200b1: return "market.advanced_search.m_200_b_1".localized
        case .m200b2: return "market.advanced_search.m_200_b_2".localized
        case .m500b2: return "market.advanced_search.m_500_b_2".localized
        case .b1b5: return "market.advanced_search.b_1_b_5".localized
        case .b1b10: return "market.advanced_search.b_1_b_10".localized
        case .b2b10: return "market.advanced_search.b_2_b_10".localized
        case .b10b50: return "market.advanced_search.b_10_b_50".localized
        case .b10b100: return "market.advanced_search.b_10_b_100".localized
        case .b100b500: return "market.advanced_search.b_100_b_500".localized
        case .moreB5: return "market.advanced_search.more_5_b".localized
        case .moreB10: return "market.advanced_search.more_10_b".localized
        case .moreB50: return "market.advanced_search.more_50_b".localized
        case .moreB500: return "market.advanced_search.more_500_b".localized
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
