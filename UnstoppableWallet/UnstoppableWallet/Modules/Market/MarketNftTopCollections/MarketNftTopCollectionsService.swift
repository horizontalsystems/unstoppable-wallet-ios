import Combine
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

struct NftCollectionItem {
    let index: Int
    let collection: NftTopCollection
}

class MarketNftTopCollectionsService {
    typealias Item = NftCollectionItem

    private let disposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager

    private var internalState: MarketListServiceState<NftTopCollection> = .loading

    @PostPublished private(set) var state: MarketListServiceState<NftCollectionItem> = .loading

    var sortType: MarketNftTopCollectionsModule.SortType = .highestVolume { didSet { syncIfPossible() } }
    var timePeriod: HsTimePeriod { didSet { syncIfPossible() } }

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, timePeriod: HsTimePeriod) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.timePeriod = timePeriod

        sync()
    }

    private func sync() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit] in
            do {
                let collections = try await marketKit.nftTopCollections()
                self?.internalState = .loaded(items: collections, softUpdate: false, reorder: false)
                self?.sync(collections: collections)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func sync(collections: [NftTopCollection], reorder: Bool = false) {
        let sortedCollections = collections.sorted(sortType: sortType, timePeriod: timePeriod)
        let items = sortedCollections.enumerated().map { NftCollectionItem(index: $0 + 1, collection: $1) }
        state = .loaded(items: items, softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case let .loaded(collections, _, _) = internalState else {
            return
        }

        sync(collections: collections, reorder: true)
    }
}

extension MarketNftTopCollectionsService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func topCollection(uid: String) -> NftTopCollection? {
        guard case let .loaded(collections, _, _) = internalState else {
            return nil
        }

        return collections.first { $0.uid == uid }
    }

    func refresh() {
        sync()
    }
}

extension MarketNftTopCollectionsService: IMarketListNftTopCollectionDecoratorService {}
