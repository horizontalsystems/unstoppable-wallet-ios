import Combine
import Foundation
import HsExtensions
import MarketKit

class CoinMajorHoldersViewModel: ObservableObject {
    let coin: Coin
    let blockchain: Blockchain
    private let marketKit = App.shared.marketKit
    private let evmLabelManager = App.shared.evmLabelManager
    private let addressLabelMap: [String: String]
    private var tasks = Set<AnyTask>()

    @Published private(set) var state: State = .loading

    private let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .halfEven
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    init(coin: Coin, blockchain: Blockchain) {
        self.coin = coin
        self.blockchain = blockchain

        addressLabelMap = evmLabelManager.addressLabelMap()

        sync()
    }

    private func sync() {
        tasks = Set()

        if case .failed = state {
            state = .loading
        }

        Task { [weak self, marketKit, coin, blockchain] in
            do {
                let tokenHolders = try await marketKit.tokenHolders(coinUid: coin.uid, blockchainUid: blockchain.uid)
                await self?.handle(tokenHolders: tokenHolders)
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .failed
                }
            }
        }.store(in: &tasks)
    }

    private func handle(tokenHolders: TokenHolders) async {
        let stateViewItem = stateViewItem(tokenHolders: tokenHolders)

        await MainActor.run { [weak self] in
            self?.state = .loaded(stateViewItem: stateViewItem)
        }
    }

    private func stateViewItem(tokenHolders: TokenHolders) -> StateViewItem {
        percentFormatter.maximumFractionDigits = 4

        let viewItems = tokenHolders.topHolders.enumerated().map { index, item in
            ViewItem(
                order: "\(index + 1)",
                percent: percentFormatter.string(from: (item.percentage / 100) as NSNumber),
                quantity: ValueFormatter.instance.formatShort(value: item.balance, decimalCount: 0, symbol: coin.code),
                labeledAddress: addressLabelMap[item.address] ?? item.address.shortened,
                address: item.address
            )
        }

        let totalPercent = tokenHolders.topHolders.map(\.percentage).reduce(0, +)

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
    func onRetry() {
        sync()
    }
}

extension CoinMajorHoldersViewModel {
    enum State {
        case loading
        case loaded(stateViewItem: StateViewItem)
        case failed
    }

    struct StateViewItem {
        let holdersCount: String?
        let totalPercent: Decimal
        let remainingPercent: Decimal
        let percent: String?
        let viewItems: [ViewItem]
        let holdersUrl: String?
    }

    struct ViewItem: Hashable {
        let order: String
        let percent: String?
        let quantity: String?
        let labeledAddress: String
        let address: String

        static func == (lhs: ViewItem, rhs: ViewItem) -> Bool {
            lhs.order == rhs.order
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(order)
        }
    }
}
