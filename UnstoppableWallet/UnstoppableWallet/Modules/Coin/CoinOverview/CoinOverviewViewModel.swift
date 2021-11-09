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

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinOverviewService.Item>) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            errorRelay.accept(nil)
        case .completed(let item):
            viewItemRelay.accept(viewItemFactory.viewItem(item: item, currency: service.currency, fullCoin: service.fullCoin))
            loadingRelay.accept(false)
            errorRelay.accept(nil)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            errorRelay.accept("market.sync_error".localized)
        }
    }

}

extension CoinOverviewViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    var coinViewItem: CoinViewItem {
        let fullCoin = service.fullCoin

        return CoinViewItem(
                name: fullCoin.coin.name,
                marketCapRank: fullCoin.coin.marketCapRank.map { "#\($0)" },
                imageUrl: fullCoin.coin.imageUrl,
                imagePlaceholderName: fullCoin.placeholderImageName
        )
    }

    func onLoad() {
        service.sync()
    }

    func onTapRetry() {
        service.sync()
    }

}

extension CoinOverviewViewModel {

    struct CoinViewItem {
        let name: String
        let marketCapRank: String?
        let imageUrl: String
        let imagePlaceholderName: String
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
        let iconName: String
        let reference: String
        let explorerUrl: String
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
