import Foundation
import RxSwift
import RxCocoa
import CoinKit

class MarketAdvancedSearchViewModel {
    private let disposeBag = DisposeBag()

    let service: MarketAdvancedSearchService

    private let coinListViewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let marketCapViewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let volumeViewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let liquidityViewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let periodViewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let priceChangeViewItemRelay = BehaviorRelay<ViewItem?>(value: nil)

    private let outperformedBtcRelay = BehaviorRelay<Bool>(value: false)
    private let outperformedEthRelay = BehaviorRelay<Bool>(value: false)
    private let outperformedBnbRelay = BehaviorRelay<Bool>(value: false)
    private let priceCloseToATHRelay = BehaviorRelay<Bool>(value: false)
    private let priceCloseToATLRelay = BehaviorRelay<Bool>(value: false)

    private let showErrorRelay = PublishRelay<String>()
    private let showResultTitleRelay = BehaviorRelay<String?>(value: nil)
    private let showResultEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)

    init(service: MarketAdvancedSearchService) {
        self.service = service

        subscribe(disposeBag, service.stateUpdatedObservable) { [weak self] in self?.sync(state: $0) }

        subscribe(disposeBag, service.coinListUpdatedObservable) { [weak self] in self?.sync(coinList: $0) }
        subscribe(disposeBag, service.marketCapUpdatedObservable) { [weak self] in self?.sync(marketCap: $0) }
        subscribe(disposeBag, service.volumeUpdatedObservable) { [weak self] in self?.sync(volume: $0) }
        subscribe(disposeBag, service.liquidityUpdatedObservable) { [weak self] in self?.sync(liquidity: $0) }
        subscribe(disposeBag, service.periodUpdatedObservable) { [weak self] in self?.sync(period: $0) }
        subscribe(disposeBag, service.priceChangeUpdatedObservable) { [weak self] in self?.sync(priceChange: $0) }

        subscribe(disposeBag, service.outperformedBtcUpdatedObservable) { [weak self] in self?.sync(isOutperformedBtcOn: $0) }
        subscribe(disposeBag, service.outperformedEthUpdatedObservable) { [weak self] in self?.sync(isOutperformedEthOn: $0) }
        subscribe(disposeBag, service.outperformedBnbUpdatedObservable) { [weak self] in self?.sync(isOutperformedBnbOn: $0) }
        subscribe(disposeBag, service.priceCloseToATHUpdatedObservable) { [weak self] in self?.sync(isPriceCloseToATHOn: $0) }
        subscribe(disposeBag, service.priceCloseToATLUpdatedObservable) { [weak self] in self?.sync(isPriceCloseToATLOn: $0) }

        sync(coinList: service.coinListCount)
        sync(marketCap: service.marketCap)
        sync(volume: service.volume)
        sync(liquidity: service.liquidity)
        sync(period: service.period)
        sync(priceChange: service.priceChange)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<Int>) {
        loadingRelay.accept(state.isLoading)

        switch state {
        case .loading:
            showResultEnabledRelay.accept(false)
            showResultTitleRelay.accept(nil)
        case .completed(let count):
            showResultEnabledRelay.accept(count > 0)
            showResultTitleRelay.accept(["market.advanced_search.show_results".localized, "\(count)"].joined(separator: ": "))
        case .failed(let error):
            showResultEnabledRelay.accept(false)
            showResultTitleRelay.accept("market.advanced_search.show_results".localized)

            showErrorRelay.accept(error.convertedError.smartDescription)
        }
    }

    private func sync(coinList: MarketAdvancedSearchService.CoinListCount) {
        coinListViewItemRelay.accept(ViewItem(value: service.coinListCount.title, valueColor: .normal))
    }

    private func sync(marketCap: MarketAdvancedSearchService.ValueFilter) {
        marketCapViewItemRelay.accept(ViewItem(value: service.marketCap.title, valueColor: service.marketCap.valueColor))
    }

    private func sync(volume: MarketAdvancedSearchService.ValueFilter) {
        volumeViewItemRelay.accept(ViewItem(value: service.volume.title, valueColor: service.volume.valueColor))
    }

    private func sync(liquidity: MarketAdvancedSearchService.ValueFilter) {
        liquidityViewItemRelay.accept(ViewItem(value: service.liquidity.title, valueColor: service.liquidity.valueColor))
    }

    private func sync(period: MarketAdvancedSearchService.PricePeriodFilter) {
        periodViewItemRelay.accept(ViewItem(value: service.period.title, valueColor: service.period.valueColor))
    }

    private func sync(priceChange: MarketAdvancedSearchService.PriceChangeFilter) {
        priceChangeViewItemRelay.accept(ViewItem(value: service.priceChange.title, valueColor: service.priceChange.valueColor))
    }

    private func sync(isOutperformedBtcOn: Bool) {
        outperformedBtcRelay.accept(isOutperformedBtcOn)
    }

    private func sync(isOutperformedEthOn: Bool) {
        outperformedEthRelay.accept(isOutperformedEthOn)
    }

    private func sync(isOutperformedBnbOn: Bool) {
        outperformedBnbRelay.accept(isOutperformedBnbOn)
    }

    private func sync(isPriceCloseToATHOn: Bool) {
        priceCloseToATHRelay.accept(isPriceCloseToATHOn)
    }

    private func sync(isPriceCloseToATLOn: Bool) {
        priceCloseToATLRelay.accept(isPriceCloseToATLOn)
    }

}

extension MarketAdvancedSearchViewModel {

    var coinListViewItemDriver: Driver<ViewItem?> {
        coinListViewItemRelay.asDriver()
    }

    var marketCapViewItemDriver: Driver<ViewItem?> {
        marketCapViewItemRelay.asDriver()
    }

    var volumeViewItemDriver: Driver<ViewItem?> {
        volumeViewItemRelay.asDriver()
    }

    var liquidityViewItemDriver: Driver<ViewItem?> {
        liquidityViewItemRelay.asDriver()
    }

    var periodViewItemDriver: Driver<ViewItem?> {
        periodViewItemRelay.asDriver()
    }

    var priceChangeViewItemDriver: Driver<ViewItem?> {
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
        priceCloseToATHRelay.asDriver()
    }

    var priceCloseToATLDriver: Driver<Bool> {
        priceCloseToATLRelay.asDriver()
    }

    var showErrorSignal: Signal<String> {
        showErrorRelay.asSignal()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var showResultTitleDriver: Driver<String?> {
        showResultTitleRelay.asDriver()
    }

    var showResultEnabledDriver: Driver<Bool> {
        showResultEnabledRelay.asDriver()
    }

    var coinListViewItems: [FilterViewItem] {
        MarketAdvancedSearchService
                .CoinListCount
                .allCases
                .map { FilterViewItem(title: $0.title, color: .normal, selected: service.coinListCount == $0) }
    }

    var marketCapViewItems: [FilterViewItem] {
        MarketAdvancedSearchService
                .ValueFilter
                .allCases
                .map { FilterViewItem(title: $0.title, color: $0.valueColor, selected: service.marketCap == $0) }
    }

    var volumeViewItems: [FilterViewItem] {
        MarketAdvancedSearchService
                .ValueFilter
                .allCases
                .map { FilterViewItem(title: $0.title, color: $0.valueColor, selected: service.volume == $0) }
    }

    var liquidityViewItems: [FilterViewItem] {
        MarketAdvancedSearchService
                .ValueFilter
                .allCases
                .map { FilterViewItem(title: $0.title, color: $0.valueColor, selected: service.liquidity == $0) }
    }

    var periodViewItems: [FilterViewItem] {
        MarketAdvancedSearchService
                .PricePeriodFilter
                .allCases
                .map { FilterViewItem(title: $0.title, color: $0.valueColor, selected: service.period == $0) }
    }

    var priceChangeViewItems: [FilterViewItem] {
        MarketAdvancedSearchService
                .PriceChangeFilter
                .allCases
                .map { FilterViewItem(title: $0.title, color: $0.valueColor, selected: service.priceChange == $0) }
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

    func setLiquidity(at index: Int) {
        service.liquidity = MarketAdvancedSearchService.ValueFilter.allCases[index]
    }

    func setPeriod(at index: Int) {
        service.period = MarketAdvancedSearchService.PricePeriodFilter.allCases[index]
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
        service.priceCloseToATH = isOn
    }

    func setPriceCloseToATL(isOn: Bool) {
        service.priceCloseToATL = isOn
    }

    func resetAll() {
        service.coinListCount = .top250
        service.volume = .none
        service.marketCap = .none
        service.liquidity = .none
        service.period = .day
        service.priceChange = .none

        service.outperformedBtc = false
        service.outperformedEth = false
        service.outperformedBnb = false
        service.priceCloseToATL = false
        service.priceCloseToATH = false
    }

}

extension MarketAdvancedSearchViewModel {

    struct FilterViewItem {
        let title: String
        let color: ValueColor
        let selected: Bool
    }

    enum ValueColor {
        case normal
        case positive
        case negative
        case none
    }

    struct ViewItem {
        let value: String
        let valueColor: ValueColor
    }

    enum State {
        case loading
        case loaded(Int)
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

    var valueColor: MarketAdvancedSearchViewModel.ValueColor {
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

    var valueColor: MarketAdvancedSearchViewModel.ValueColor {
        switch self {
        case .none: return .none
        case .plus10, .plus25, .plus50, .plus100: return .positive
        case .minus10, .minus25, .minus50, .minus100: return .negative
        }
    }

}

extension MarketAdvancedSearchService.PricePeriodFilter {

    var title: String {
        switch self {
        case .day: return "market.advanced_search.day".localized
        case .week: return "market.advanced_search.week".localized
        case .week2: return "market.advanced_search.week2".localized
        case .month: return "market.advanced_search.month".localized
        case .month6: return "market.advanced_search.month6".localized
        case .year: return "market.advanced_search.year".localized
        }
    }

    var valueColor: MarketAdvancedSearchViewModel.ValueColor {
        self == .none ? .none : .normal
    }

}
