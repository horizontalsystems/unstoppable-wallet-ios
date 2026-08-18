import Combine
import Foundation
import MarketKit
import MoneroKit
import SwiftUI

struct MoneroOutputSelectorView: View {
    @StateObject var viewModel: MoneroOutputSelectorViewModel

    init(handler: MoneroPreSendHandler) {
        _viewModel = StateObject(wrappedValue: MoneroOutputSelectorViewModel(handler: handler))
    }

    var body: some View {
        ThemeView {
            VStack {
                ListSection {
                    ListRow(minHeight: .heightDoubleLineCell) {
                        HStack(spacing: .margin8) {
                            VStack(spacing: 1) {
                                Text("send.available_balance".localized).themeSubhead2(color: .themeGray)
                            }

                            Spacer()

                            VStack(spacing: 1) {
                                Text(viewModel.availableBalanceCoinValue).themeSubhead1(color: .themeLeah, alignment: .trailing)
                                if let subtitle = viewModel.availableBalanceFiatValue {
                                    Text(subtitle).themeSubhead2(alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))

                ScrollView {
                    ListSection {
                        ForEach(viewModel.outputsViewItems) { viewItem in
                            output(viewItem: viewItem)
                        }
                    }
                    .themeListStyle(.transparent)
                }

                HorizontalDivider(color: .themeBlade, height: .heightOneDp)

                HStack {
                    Button(action: {
                        viewModel.unselectAll()
                    }) {
                        Text("send.unselect_all".localized).themeBody(color: viewModel.selectedSet.isEmpty ? .themeGray50 : .themeJacob)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.selectAll()
                    }) {
                        Text("send.select_all".localized).themeBody(color: viewModel.allSelected ? .themeGray50 : .themeJacob, alignment: .trailing)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: CGFloat(43), trailing: .margin16))
            }
        }
        .navigationTitle("send.unspent_outputs".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder func output(viewItem: MoneroOutputSelectorViewModel.OutputViewItem) -> some View {
        ClickableRow(action: {
            viewModel.toggle(viewItem: viewItem)
        }) {
            HStack(spacing: .margin16) {
                CheckBoxUiView(checked: .init(get: { viewModel.selectedSet.contains(viewItem.id) }, set: { _ in }))

                VStack(spacing: 1) {
                    Text(viewItem.date).themeBody()
                    Text(viewItem.address).themeSubhead2()
                }
                Spacer()

                VStack(spacing: 1) {
                    Text(viewItem.coinValue).themeBody(alignment: .trailing)
                    if let subtitle = viewItem.fiatValue {
                        Text(subtitle).themeSubhead2(alignment: .trailing)
                    }
                }
            }
        }
    }
}

class MoneroOutputSelectorViewModel: ObservableObject {
    private var rateCancellable: AnyCancellable?
    private var balanceCancellable: AnyCancellable?

    @Published var outputsViewItems = [OutputViewItem]()
    @Published var selectedSet = Set<String>()

    @Published var availableBalanceCoinValue = ""
    @Published var availableBalanceFiatValue: String? = ""
    @Published var allSelected: Bool = true

    private let handler: MoneroPreSendHandler
    private var rate: Decimal?

    init(handler: MoneroPreSendHandler) {
        self.handler = handler

        let currency = Core.shared.currencyManager.baseCurrency
        rate = Core.shared.marketKit.coinPrice(coinUid: handler.token.coin.uid, currencyCode: currency.code)?.value
        rateCancellable = Core.shared.marketKit.coinPricePublisher(coinUid: handler.token.coin.uid, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] price in
                self?.rate = price.value
                self?.sync()
            }

        // Outputs load on a background queue; refresh the list when they (or the balance) change
        balanceCancellable = handler.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.sync()
            }

        sync()
    }

    private func sync() {
        let all = handler.allOutputs.sorted { output, output2 in
            let timestamp = handler.transactionTimestamps[output.txHash] ?? 0
            let timestamp2 = handler.transactionTimestamps[output2.txHash] ?? 0

            if timestamp > timestamp2 { return true }
            if timestamp == timestamp2, output.amount > output2.amount { return true }
            return false
        }

        let selectedIds = (handler.customOutputs ?? all).map(\.keyImage)
        selectedSet = Set(selectedIds)

        outputsViewItems = all.map { viewItem(unspentOutput: $0) }
        allSelected = all.count == selectedSet.count

        let appValue = appValue(piconeroValue: nil, decimalValue: handler.availableBalance)
        let currencyValue = rate.flatMap {
            CurrencyValue(currency: Core.shared.currencyManager.baseCurrency, value: appValue.value * $0)
        }

        availableBalanceCoinValue = appValue.formattedFull() ?? "n/a".localized
        availableBalanceFiatValue = currencyValue.flatMap(\.formattedFull)
    }

    private func viewItem(unspentOutput: MoneroKit.UnspentOutput) -> OutputViewItem {
        let appValue = appValue(piconeroValue: unspentOutput.amount, decimalValue: nil)
        let currencyValue = rate.flatMap {
            CurrencyValue(currency: Core.shared.currencyManager.baseCurrency, value: appValue.value * $0)
        }

        let date = handler.transactionTimestamps[unspentOutput.txHash].map {
            DateHelper.instance.formatShortDateOnly(date: Date(timeIntervalSince1970: TimeInterval($0)))
        }

        return OutputViewItem(
            keyImage: unspentOutput.keyImage,
            date: date ?? "n/a".localized,
            address: handler.subaddress(index: Int(unspentOutput.subaddressIndex))?.shortened ?? "n/a".localized,
            coinValue: appValue.formattedFull() ?? "n/a".localized,
            fiatValue: currencyValue.flatMap(\.formattedFull)
        )
    }

    private func appValue(piconeroValue: UInt64?, decimalValue: Decimal?) -> AppValue {
        let value: Decimal
        if let piconeroValue {
            value = Decimal(piconeroValue) / pow(10, handler.token.decimals)
        } else {
            value = decimalValue ?? 0
        }

        return AppValue(token: handler.token, value: value)
    }
}

extension MoneroOutputSelectorViewModel {
    func toggle(viewItem: OutputViewItem) {
        handler.customOutputs = handler.allOutputs.filter { output in
            if viewItem.id == output.keyImage {
                return !selectedSet.contains(output.keyImage)
            } else {
                return selectedSet.contains(output.keyImage)
            }
        }

        sync()
    }

    func unselectAll() {
        handler.customOutputs = []
        sync()
    }

    func selectAll() {
        handler.customOutputs = handler.allOutputs
        sync()
    }
}

extension MoneroOutputSelectorViewModel {
    struct OutputViewItem: Hashable, Identifiable, Equatable {
        let keyImage: String
        let date: String
        let address: String
        let coinValue: String
        let fiatValue: String?

        var id: String { keyImage }

        func hash(into hasher: inout Hasher) {
            hasher.combine(keyImage)
        }
    }
}
