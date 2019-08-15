import Foundation

class BalanceItemDataSource {
    private let sorter: IBalanceSorter

    var sortType: BalanceSortType {
        didSet { items = sorter.sort(items: items, sort: sortType) }
    }
    var items: [BalanceItem]
    var currency: Currency?

    init(sorter: IBalanceSorter) {
        self.sorter = sorter

        items = [BalanceItem]()
        sortType = .name
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
        return items.firstIndex(where: { $0.wallet == wallet })
    }

    func indices(for coinCode: String) -> [Int] {
        var indices = [Int]()

        for (index, item) in items.enumerated() {
            if item.wallet.coin.code == coinCode {
                indices.append(index)
            }
        }

        return indices
    }

    func set(balance: Decimal, index: Int) {
        items[index].balance = balance
    }

    func set(state: AdapterState, index: Int) {
        items[index].state = state

        let canSort = items.filter {
            $0.state != .synced
        }.isEmpty
        if canSort {
            items = sorter.sort(items: items, sort: sortType)
        }
    }

    func set(rate: Rate, index: Int) {
        items[index].rate = rate
        items = sorter.sort(items: items, sort: sortType)
    }

    func clearRates() {
        for i in 0..<items.count {
            items[i].rate = nil
        }
    }

    func set(items: [BalanceItem]) {
        self.items = sorter.sort(items: items, sort: sortType)
    }

}
