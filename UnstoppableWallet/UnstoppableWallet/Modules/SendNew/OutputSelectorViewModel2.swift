import BitcoinCore
import Combine
import Foundation
import MarketKit

class OutputSelectorViewModel2: ObservableObject {
    private var rateCancellable: AnyCancellable?

    @Published var outputsViewItems = [OutputViewItem]()
    @Published var selectedSet = Set<String>()

    @Published var availableBalanceCoinValue = ""
    @Published var availableBalanceFiatValue: String? = ""
    @Published var resetEnabled = true
    @Published var allSelected: Bool = true

    private let handler: BitcoinPreSendHandler
    private var rate: Decimal?

    init(handler: BitcoinPreSendHandler) {
        self.handler = handler

        let currency = App.shared.currencyManager.baseCurrency
        rate = App.shared.marketKit.coinPrice(coinUid: handler.token.coin.uid, currencyCode: currency.code)?.value
        rateCancellable = App.shared.marketKit.coinPricePublisher(coinUid: handler.token.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in
                self?.rate = price.value
                self?.sync()
            }

        sync()
    }

    private func sync() {
        // create outputs viewItems
        let all = handler.allUtxos.sorted { output, output2 in
            if output.timestamp > output2.timestamp { return true }
            if output.timestamp == output2.timestamp, output.outputIndex < output2.outputIndex { return true }
            return false
        }

        let selectedIds = (handler.customUtxos ?? all).map {
            OutputViewItem.id(hash: $0.transactionHash, index: $0.outputIndex)
        }
        selectedSet = Set(selectedIds)

        outputsViewItems = all.map { viewItem(unspentOutput: $0) }
        allSelected = all.count == selectedSet.count

        let coinValue = coinValue(satoshiValue: handler.availableBalance)
        let currencyValue = rate.flatMap {
            CurrencyValue(currency: App.shared.currencyManager.baseCurrency, value: coinValue.value * $0)
        }

        availableBalanceCoinValue = coinValue.formattedFull ?? "n/a".localized
        availableBalanceFiatValue = currencyValue.flatMap(\.formattedFull)
    }

    private func viewItem(unspentOutput: UnspentOutputInfo) -> OutputViewItem {
        let coinValue = coinValue(satoshiValue: unspentOutput.value)
        let currencyValue = rate.flatMap {
            CurrencyValue(currency: App.shared.currencyManager.baseCurrency, value: coinValue.value * $0)
        }

        return OutputViewItem(
            outputIndex: unspentOutput.outputIndex,
            transactionHash: unspentOutput.transactionHash,
            date: DateHelper.instance.formatShortDateOnly(date: Date(timeIntervalSince1970: TimeInterval(unspentOutput.timestamp))),
            address: unspentOutput.address?.shortened ?? "n/a".localized,
            coinValue: coinValue.formattedFull ?? "n/a".localized,
            fiatValue: currencyValue.flatMap(\.formattedFull)
        )
    }

    private func coinValue(satoshiValue: Int) -> CoinValue {
        let coinRate = pow(10, handler.token.decimals)
        let decimalValue = Decimal(satoshiValue) / coinRate
        return CoinValue(kind: .token(token: handler.token), value: decimalValue)
    }
}

extension OutputSelectorViewModel2 {
    func toggle(viewItem: OutputViewItem) {
        handler.customUtxos = handler.allUtxos.filter {
            let id = OutputViewItem.id(hash: $0.transactionHash, index: $0.outputIndex)

            if viewItem.id == id {
                return !selectedSet.contains(id)
            } else {
                return selectedSet.contains(id)
            }
        }

        sync()
    }

    func unselectAll() {
        handler.customUtxos = []
        sync()
    }

    func selectAll() {
        handler.customUtxos = handler.allUtxos
        sync()
    }

    func onTapDone() {}

    func reset() {
        handler.customUtxos = nil
        resetEnabled = false
    }
}

extension OutputSelectorViewModel2 {
    struct ChangeViewItem: Equatable {
        let address: String
        let title: String
        let subtitle: String?

        static func == (lhs: ChangeViewItem, rhs: ChangeViewItem) -> Bool {
            lhs.address == rhs.address &&
                lhs.title == rhs.title &&
                lhs.subtitle == rhs.subtitle
        }
    }

    struct OutputViewItem: Hashable, Identifiable, Equatable {
        let outputIndex: Int
        let transactionHash: Data
        let date: String
        let address: String
        let coinValue: String
        let fiatValue: String?

        var id: String {
            Self.id(hash: transactionHash, index: outputIndex)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(outputIndex)
            hasher.combine(transactionHash)
        }

        static func id(hash: Data, index: Int) -> String { [hash.hs.hexString, index.description].joined(separator: "_") }
    }
}
