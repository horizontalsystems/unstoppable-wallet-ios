import Foundation

class BalanceItemDataSource {
    private let sorter: IBalanceSorter

    var sortType: BalanceSortType {
        didSet { items = sorter.sort(items: items, sort: sortType) }
    }
    var items: [BalanceItem]
    var currency: Currency
    var statsModeOn: Bool

    init(sorter: IBalanceSorter, baseCurrency: Currency) {
        self.sorter = sorter
        self.currency = baseCurrency

        items = [BalanceItem]()
        sortType = .name
        statsModeOn = false
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

    func indexes(for coinCode: String) -> [Int] {
        var indexes = [Int]()

        for (index, item) in items.enumerated() {
            if item.wallet.coin.code == coinCode {
                indexes.append(index)
            }
        }

        return indexes
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

    func set(chartPoints: [ChartPoint], index: Int) {
        items[index].statLoadDidFail = false
        items[index].chartPoints = chartPoints
        items[index].percentDelta = {
            if let first = chartPoints.first, let last = chartPoints.last {
                let deltaPercent = -(first.value - last.value) / last.value * 100
                let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
                return NSDecimalNumber(decimal: deltaPercent).rounding(accordingToBehavior: handler).decimalValue
            }
            return 0
        }()
    }

    func setStatsFailed(index: Int) {
        items[index].chartPoints = []
        items[index].percentDelta = 0
        items[index].statLoadDidFail = true
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
