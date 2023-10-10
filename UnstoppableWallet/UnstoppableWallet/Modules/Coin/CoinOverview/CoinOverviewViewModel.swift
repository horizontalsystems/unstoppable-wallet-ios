import ComponentKit
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit

class CoinOverviewViewModel {
    private let service: CoinOverviewService
    private let viewItemFactory = CoinOverviewViewItemFactory()
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)
    private let hudRelay = PublishRelay<HudHelper.BannerType>()

    private var typesShown = false

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
            syncErrorRelay.accept(false)
        case let .completed(item):
            viewItemRelay.accept(viewItemFactory.viewItem(item: item, currency: service.currency, typesShown: typesShown))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
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

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var hudSignal: Signal<HudHelper.BannerType> {
        hudRelay.asSignal()
    }

    func onLoad() {
        service.sync()
    }

    func onTapRetry() {
        service.sync()
    }

    func onTapAddToWallet(index: Int) {
        do {
            try service.editWallet(index: index, add: true)
            hudRelay.accept(.addedToWallet)
        } catch {}
    }

    func onTapAddedToWallet(index: Int) {
        do {
            try service.editWallet(index: index, add: false)
            hudRelay.accept(.removedFromWallet)
        } catch {}
    }

    func onTap(typesAction: TypesAction) {
        guard case let .completed(item) = service.state else {
            return
        }

        switch typesAction {
        case .showMore: typesShown = true
        case .showLess: typesShown = false
        }

        viewItemRelay.accept(viewItemFactory.viewItem(item: item, currency: service.currency, typesShown: typesShown))
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
        let coinViewItem: CoinViewItem

        let marketCapRank: String?
        let marketCap: String?
        let totalSupply: String?
        let circulatingSupply: String?
        let volume24h: String?
        let dilutedMarketCap: String?
        let genesisDate: String?

        let performance: [[PerformanceViewItem]]
        let types: TypesViewItem?
        let description: String
        let guideUrl: URL?
        let links: [LinkViewItem]
    }

    struct TypesViewItem {
        let title: String
        let viewItems: [TypeViewItem]
        let action: TypesAction?
    }

    enum TypesAction: String {
        case showMore
        case showLess

        var title: String {
            switch self {
            case .showMore: return "coin_overview.show_more".localized
            case .showLess: return "coin_overview.show_less".localized
            }
        }
    }

    struct TypeViewItem {
        let iconUrl: String
        let title: String?
        let subtitle: String?
        let reference: String?
        let explorerUrl: String?
        let showAdd: Bool
        let showAdded: Bool
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
