import MarketKit
import SwiftUI

struct CrossPayPreSendTabView: View {
    @ObservedObject var viewModel: CrossPayPreSendViewModel
    let addressVisible: Bool

    @Binding var path: NavigationPath
    @Binding var isPresented: Bool

    var body: some View {
        PreSendFormView(viewModel: viewModel, addressVisible: addressVisible, path: $path, isPresented: $isPresented, onSelectToken: presentTokenSelect) { _ in
            payView()
        } footer: {
            infoCard()
        }
    }

    @ViewBuilder private func payView() -> some View {
        HStack(spacing: 8) {
            ThemeText("cross_pay.you_will_pay".localized, style: .subhead, colorStyle: .secondary)

            Spacer()

            if viewModel.quoteState == .loading {
                ProgressView()
            } else {
                ThemeText(formatted(amount: payAmount, token: viewModel.tokenIn), style: .subhead, colorStyle: .yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 48)
    }

    @ViewBuilder private func infoCard() -> some View {
        AlertCardView(.init(icon: "info_filled", title: "cross_pay.info.title".localized, text: "cross_pay.info.text %@".localized(viewModel.tokenIn.coin.code), type: .regular))
            .padding(.top, 16)
            .padding(.horizontal, 16)
    }

    // Zero with no quote or on a quote error.
    private var payAmount: Decimal {
        if case let .success(payAmount) = viewModel.quoteState {
            return payAmount
        }

        return 0
    }

    private func presentTokenSelect() {
        Coordinator.shared.present { isPresented in
            MultiSwapTokenSelectView(
                title: "cross_pay.send_to".localized,
                currentToken: $viewModel.selectedTokenOut,
                otherToken: viewModel.tokenIn,
                allowExternalReceive: true,
                isPresented: isPresented
            )
        }
    }

    private func formatted(amount: Decimal, token: Token) -> String {
        let figure = ValueFormatter.instance.formatFull(value: amount, decimalCount: token.decimals) ?? "\(amount)"
        return "\(figure) \(token.coin.code)"
    }
}
