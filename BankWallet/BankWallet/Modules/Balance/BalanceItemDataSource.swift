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

    func set(items: [BalanceItem], sort: BalanceSortType, desc: Bool) {
        self.originalItems = items
        self.sort(type: sort, desc: desc)
    }

    func sort(type: BalanceSortType, desc: Bool) {
        switch type {
        case .value:
            items = originalItems.sorted { item, item2 in
                if let rate = item.rate, let rate2 = item2.rate {
                    return item.balance * rate.value > item2.balance * rate2.value
                }
                return item.balance > item2.balance
            }
        case .az:
            items = originalItems.sorted { item, item2 in
                return item.coin.title.caseInsensitiveCompare(item2.coin.title) == .orderedAscending
            }
        case .manual:
            items = originalItems
        }
        if desc {
            items.reverse()
        }
    }

}
