import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class MarketOverviewNftCollectionsViewModel {
    private let service: MarketOverviewNftCollectionsService
    private let disposeBag = DisposeBag()

    private let statusRelay = BehaviorRelay<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>>(value: .loading)

    init(service: MarketOverviewNftCollectionsService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(status: $0)
        }
    }

    private func sync(status: DataStatus<[NftCollection]>) {
        statusRelay.accept(status.map({ listItems in
            viewItems(listItems: listItems)
        }))
    }

    private func viewItems(listItems: [NftCollection]) -> [MarketOverviewTopCoinsViewModel.TopViewItem] {
        [
            MarketOverviewTopCoinsViewModel.TopViewItem(
                    listType: .topCollections,
                    imageName: "image_2_20",
                    title: "market.top.top_collections".localized,
                    listViewItems: listItems.enumerated().map {
                        globalViewItem(collection: $1, index: $0 + 1)
                    }
            )
        ]
    }

    func globalViewItem(collection: NftCollection, index: Int) -> MarketModule.ListViewItem {
        var floorPriceString = "---"
        var iconPlaceholderName = "icon_placeholder_24"
        if let floorPrice = collection.stats.floorPrice {
            iconPlaceholderName = floorPrice.platformCoin.fullCoin.placeholderImageName

            let coinValue = CoinValue(kind: .platformCoin(platformCoin: floorPrice.platformCoin), value: floorPrice.value)
            if let value = ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) {
                floorPriceString = "market.top.floor_price".localized + " " + value
            }
        }


        var volumeString = "n/a".localized
        if let volume = collection.stats.sevenDayVolume, let value = CurrencyCompactFormatter.instance.format(symbol: volume.platformCoin.code, value: volume.value) {
            volumeString = value
        }

        let dataValue: MarketModule.MarketDataValue = .diff(collection.stats.priceChange)

        return MarketModule.ListViewItem(
                uid: collection.uid,
                iconUrl: collection.imageUrl ?? "",
                iconPlaceholderName: iconPlaceholderName,
                name: collection.name,
                code: floorPriceString,
                rank: "\(index)",
                price: volumeString,
                dataValue: dataValue
        )
    }

}

extension MarketOverviewNftCollectionsViewModel: IMarketOverviewTopCoinsViewModel {

    var statusDriver: Driver<DataStatus<[MarketOverviewTopCoinsViewModel.TopViewItem]>> {
        statusRelay.asDriver()
    }
    var marketTops: [String] {
        []
    }

    func marketTop(listType: MarketOverviewTopCoinsService.ListType) -> MarketModule.MarketTop {
        .top250
    }

    func marketTopIndex(listType: MarketOverviewTopCoinsService.ListType) -> Int {
        0
    }

    func onSelect(marketTopIndex: Int, listType: MarketOverviewTopCoinsService.ListType) {
    }

    func refresh() {
        service.refresh()
    }

    func collection(uid: String) -> NftCollection? {
        service.collection(uid: uid)
    }

}
