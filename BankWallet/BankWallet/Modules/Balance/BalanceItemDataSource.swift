import Foundation

class BalanceItemDataSource: IBalanceItemDataSource {
    private var originalItems = [BalanceItem]()
    var items: [BalanceItem]
    var currency: Currency?

    init() {
        items = [BalanceItem]()
    }

    var coinCodes: [CoinCode] {
        return items.map { $0.coin.code }
    }

    func item(at index: Int) -> BalanceItem {
        return items[index]
    }

    func index(for coinCode: CoinCode) -> Int? {
        return items.firstIndex(where: { $0.coin.code == coinCode })
    }

    func set(balance: Decimal, index: Int) {
        items[index].balance = balance
    }

    func set(state: AdapterState, index: Int) {
        items[index].state = state
    }

    func set(rate: Rate, index: Int) {
        items[index].rate = rate
    }

    func clearRates() {
        for i in 0..<items.count {
            items[i].rate = nil
        }
    }

    func set(items: [BalanceItem], sort: BalanceSortType) {
        self.originalItems = items
        self.sort(type: sort)
    }

    func sort(type: BalanceSortType) {
        switch type {
        case .value:
            items = originalItems.sorted { item, item2 in
                if item.rate == nil && item2.rate == nil {
                    return item.balance > item2.balance
                }

                return item.balance * (item.rate?.value ?? 0) > item2.balance * (item2.rate?.value ?? 0)
            }
        case .name:
            items = originalItems.sorted { item, item2 in
                return item.coin.title.caseInsensitiveCompare(item2.coin.title) == .orderedAscending
            }
        case .manual:
            items = originalItems
        }
    }

}
