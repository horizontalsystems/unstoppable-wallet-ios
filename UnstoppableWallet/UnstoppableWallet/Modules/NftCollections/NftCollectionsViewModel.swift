import RxSwift
import RxRelay
import RxCocoa

class NftCollectionsViewModel {
    private let service: NftCollectionsService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    private var expandedUids = Set<String>()

    init(service: NftCollectionsService) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        syncState()
    }

    private func syncState() {
        sync(items: service.items)
    }

    private func sync(items: [NftCollectionsService.Item]) {
        viewItemsRelay.accept(items.map { viewItem(item: $0) })
    }

    private func viewItem(item: NftCollectionsService.Item) -> ViewItem {
        let uid = item.name // todo
        let expanded = expandedUids.contains(uid)

        return ViewItem(
                uid: uid,
                imageUrl: item.imageUrl,
                name: item.name,
                count: "\(item.tokens.count)",
                expanded: expanded,
                tokenViewItems: expanded ? item.tokens.map { tokenViewItem(tokenItem: $0) } : []
        )
    }

    private func tokenViewItem(tokenItem: NftCollectionsService.TokenItem) -> TokenViewItem {
        TokenViewItem(
                uid: tokenItem.name,
                imageUrl: tokenItem.imageUrl,
                name: tokenItem.name,
                floorPrice: "\(tokenItem.floorPrice)",
                lastPrice: "\(tokenItem.lastPrice)"
        )
    }

}

extension NftCollectionsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func onTapViewItem(index: Int) {
        let uid = viewItemsRelay.value[index].uid

        if expandedUids.contains(uid) {
            expandedUids.remove(uid)
        } else {
            expandedUids.insert(uid)
        }

        syncState()
    }

}

extension NftCollectionsViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String
        let name: String
        let count: String
        let expanded: Bool
        let tokenViewItems: [TokenViewItem]
    }

    struct TokenViewItem {
        let uid: String
        let imageUrl: String
        let name: String
        let floorPrice: String
        let lastPrice: String
    }

}
