import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import UIKit

class CoinOverviewViewModel {
    private let service: CoinOverviewService
    private let viewItemFactory = CoinOverviewViewItemFactory()
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: CoinOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinOverviewService.Item>) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .completed(let item):
            stateRelay.accept(.loaded(viewItem: viewItemFactory.viewItem(item: item, currency: service.currency, fullCoin: service.fullCoin)))
        case .failed:
            stateRelay.accept(.failed(error: "market.sync_error".localized))
        }
    }

}

extension CoinOverviewViewModel {

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    func onLoad() {
        service.sync()
    }

}

extension CoinOverviewViewModel {

    enum State {
        case loading
        case loaded(viewItem: ViewItem)
        case failed(error: String)
    }

    struct ViewItem {
        let marketCapRank: String?
        let marketCap: String?
        let totalSupply: String?
        let circulatingSupply: String?
        let volume24h: String?
        let dilutedMarketCap: String?
        let tvl: String?
        let genesisDate: String?

        let performance: [[PerformanceViewItem]]
        let categories: [String]?
        let contracts: [ContractViewItem]?
        let description: String
        let guideUrl: URL?
        let links: [LinkViewItem]
    }

    struct ContractViewItem {
        let title: String
        let value: String
    }

    enum PerformanceViewItem {
        case title(String)
        case subtitle(String)
        case content(String)
        case value(Decimal?)
    }

    struct LinkViewItem {
        let title: String
        let iconName: String
        let url: String
    }

}
