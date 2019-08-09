import Foundation

class BalanceItemDataSource {
    private let sorter: IBalanceSorter

    private var originalItems = [BalanceItem]()

    var sortType: BalanceSortType {
        didSet { items = sorter.sort(items: originalItems, sort: sortType) }
    }
    var items: [BalanceItem]
    var currency: Currency?

    init(sorter: IBalanceSorter) {
        self.sorter = sorter

        items = [BalanceItem]()
        sortType = .manual
    }

}

extension BalanceItemDataSource: IBalanceItemDataSource {

    var coinCodes: [CoinCode] {
        return Array(Set(items.map { $0.wallet.coin.code }))
    }

    func item(at index: Int) -> BalanceItem {
        return items[index]
    }

    func index(for wallet: Wallet) -> Int? {
        return originalItems.firstIndex(where: { $0.wallet == wallet })
    }

    func indices(for coinCode: String) -> [Int] {
        var indices = [Int]()

        for (index, item) in originalItems.enumerated() {
            if item.wallet.coin.code == coinCode {
                indices.append(index)
            }
        }

        return indices
    }

    func set(balance: Decimal, index: Int) {
        originalItems[index].balance = balance
        items = sorter.sort(items: originalItems, sort: sortType)
    }

    func set(state: AdapterState, index: Int) {
        originalItems[index].state = state
        items = sorter.sort(items: originalItems, sort: sortType)
    }

    func set(rate: Rate, index: Int) {
        originalItems[index].rate = rate
        items = sorter.sort(items: originalItems, sort: sortType)
    }

    func clearRates() {
        for i in 0..<originalItems.count {
            originalItems[i].rate = nil
        }
        items = sorter.sort(items: originalItems, sort: sortType)
    }

    func set(items: [BalanceItem]) {
        self.originalItems = items
        self.items = sorter.sort(items: originalItems, sort: sortType)
    }

}
