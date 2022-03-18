import RxSwift
import RxRelay
import RxCocoa

class NftCollectionOverviewViewModel {
    private let service: NftCollectionOverviewService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<NftCollectionOverviewService.Item>) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .completed(let item):
            viewItemRelay.accept(viewItem(item: item))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func viewItem(item: NftCollectionOverviewService.Item) -> ViewItem {
        let collection = item.collection

        return ViewItem(
                logoImageUrl: collection.imageUrl,
                name: collection.name,
                description: collection.description,
                contracts: collection.contracts.map { contractViewItem(contract: $0) },
                links: linkViewItems(collection: collection)
        )
    }

    private func contractViewItem(contract: NftCollection.Contract) -> ContractViewItem {
        ContractViewItem(
                iconName: "ethereum_24",
                reference: contract.address,
                explorerUrl: "https://etherscan.io/token/\(contract.address)"
        )
    }

    private func linkViewItems(collection: NftCollection) -> [LinkViewItem] {
        var viewItems = [LinkViewItem]()

        if let url = collection.externalUrl {
            viewItems.append(LinkViewItem(type: .website, url: url))
        }

        viewItems.append(LinkViewItem(type: .openSea, url: "https://opensea.io/collection/\(collection.uid)"))

        if let url = collection.discordUrl {
            viewItems.append(LinkViewItem(type: .discord, url: url))
        }
        if let username = collection.twitterUsername {
            viewItems.append(LinkViewItem(type: .twitter, url: "https://twitter.com/\(username)"))
        }

        return viewItems
    }

}

extension NftCollectionOverviewViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
        service.resync()
    }

}

extension NftCollectionOverviewViewModel {

    struct ViewItem {
        let logoImageUrl: String?
        let name: String
        let description: String?
        let contracts: [ContractViewItem]
        let links: [LinkViewItem]
    }

    struct ContractViewItem {
        let iconName: String
        let reference: String
        let explorerUrl: String
    }

    struct LinkViewItem {
        let type: LinkType
        let url: String
    }

    enum LinkType {
        case website
        case openSea
        case discord
        case twitter
    }

}
