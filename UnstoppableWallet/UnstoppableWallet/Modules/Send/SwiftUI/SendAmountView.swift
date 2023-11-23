import SwiftUI
import ThemeKit

struct SendAmountView: View {
    @ObservedObject var viewModel: SendAmountViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                switch viewModel.inputType {
                case .coin: EmptyView()
                case .currency: Text(viewModel.currency.symbol).textBody(color: .themeJacob)
                }

                TextField(
                    "0",
                    text: $viewModel.text,
                    onEditingChanged: { print("changed: \($0)") },
                    onCommit: { print("commit") }
                )
                .keyboardType(.decimalPad)
                .foregroundColor(viewModel.inputType == .coin ? .themeLeah : .themeJacob)
                .accentColor(.themeYellow)
                .padding(.vertical, .margin12)

                if viewModel.text.isEmpty {
                    Button(action: { print("tap Max") }) {
                        Text("send.max_button".localized)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button(action: { print("tap Delete") }) {
                        Image("trash_20").renderingMode(.template)
                    }
                    .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                }
            }
            .padding(.horizontal, .margin16)

            HorizontalDivider(color: .themeSteel20)
                .padding(.horizontal, .margin8)

            Button(action: { viewModel.toggleInputType() }) {
                switch viewModel.inputType {
                case .coin: Text(ValueFormatter.instance.formatFull(currencyValue: CurrencyValue(currency: viewModel.currency, value: viewModel.currencyAmount)) ?? "").themeSubhead2(color: .themeJacob)
                case .currency: Text(ValueFormatter.instance.formatFull(coinValue: CoinValue(kind: .token(token: viewModel.token), value: viewModel.coinAmount)) ?? "").themeSubhead2(color: .themeLeah)
                }
            }
            .padding(.horizontal, .margin16)
            .padding(.vertical, .margin12)
        }
        .modifier(InputRowModifier())
    }
}
