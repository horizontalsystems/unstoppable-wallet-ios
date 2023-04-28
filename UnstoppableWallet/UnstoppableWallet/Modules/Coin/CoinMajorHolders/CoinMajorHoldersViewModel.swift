import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class CoinMajorHoldersViewModel {
    private let service: CoinMajorHoldersService
    private var cancellables = Set<AnyCancellable>()

    private let stateViewItemRelay = BehaviorRelay<StateViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .halfEven
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    init(service: CoinMajorHoldersService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: DataStatus<TokenHolders>) {
        switch state {
        case .loading:
            stateViewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .completed(let tokenHolders):
            stateViewItemRelay.accept(stateViewItem(tokenHolders: tokenHolders))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            stateViewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func stateViewItem(tokenHolders: TokenHolders) -> StateViewItem {
        percentFormatter.maximumFractionDigits = 4

        let viewItems = tokenHolders.topHolders.enumerated().map { index, item in
            ViewItem(
                    order: "\(index + 1)",
                    percent: percentFormatter.string(from: (item.percentage / 100) as NSNumber),
                    quantity: ValueFormatter.instance.formatShort(value: item.balance, decimalCount: 0, symbol: service.coin.code),
                    labeledAddress: service.labeled(address: item.address),
                    address: item.address
            )
        }

        let totalPercent = tokenHolders.topHolders.map { $0.percentage }.reduce(0, +)

        percentFormatter.maximumFractionDigits = 2
        let percent = percentFormatter.string(from: (totalPercent / 100) as NSNumber)

        return StateViewItem(
                holdersCount: ValueFormatter.instance.formatShort(value: tokenHolders.count),
                totalPercent: totalPercent,
                remainingPercent: 100.0 - totalPercent,
                percent: percent,
                viewItems: viewItems,
                holdersUrl: tokenHolders.holdersUrl
        )
    }

}

extension CoinMajorHoldersViewModel {

    var stateViewItemDriver: Driver<StateViewItem?> {
        stateViewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var blockchainName: String {
        service.blockchain.name
    }

    var blockchainType: BlockchainType {
        service.blockchain.type
    }

    func onTapRetry() {
        service.refresh()
    }

}

extension CoinMajorHoldersViewModel {

    struct ViewItem {
        let order: String
        let percent: String?
        let quantity: String?
        let labeledAddress: String
        let address: String
    }

    struct StateViewItem {
        let holdersCount: String?
        let totalPercent: Decimal
        let remainingPercent: Decimal
        let percent: String?
        let viewItems: [ViewItem]
        let holdersUrl: String?
    }

}
