import MarketKit
import SwiftUI

struct MultiSwapSuggestedPathView: View {
    private static let swapFirstHopUrl = "unstoppable://swap_first_hop"

    let path: SwapPath
    let onSwapFirstHop: (Token) -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                ThemeText("swap.suggested_path.no_quotes_available".localized, style: .subhead, colorStyle: .primary)
                ThemeText(text(), style: .caption)
                    .environment(\.openURL, OpenURLAction { _ in
                        onSwapFirstHop(path.intermediateToken)
                        return .handled
                    })
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                hopView(token: path.tokenIn)
                separatorView()
                hopView(token: path.intermediateToken)
                separatorView()
                hopView(token: path.tokenOut)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.themeTyler))
    }

    @ViewBuilder private func hopView(token: Token) -> some View {
        CoinIconView(token: token, size: 32)
    }

    @ViewBuilder private func separatorView() -> some View {
        ThemeImage("arrow_m_right", size: 16, colorStyle: .secondary)
    }

    private func text() -> AttributedString {
        let string = "swap.suggested_path.text".localized
        let components = string.components(separatedBy: "%@")

        guard components.count == 4 else {
            return AttributedString(string)
        }

        var result = AttributedString("")

        if !components[0].isEmpty { result.append(AttributedString(components[0])) }
        result.append(swapPart())
        if !components[1].isEmpty { result.append(AttributedString(components[1])) }
        result.append(AttributedString(path.intermediateToken.coin.code))
        if !components[2].isEmpty { result.append(AttributedString(components[2])) }
        result.append(AttributedString(path.tokenOut.coin.code))
        if !components[3].isEmpty { result.append(AttributedString(components[3])) }

        return result
    }

    private func swapPart() -> AttributedString {
        var part = AttributedString("swap.suggested_path.text.part".localized(path.tokenIn.coin.code, path.intermediateToken.coin.code))

        part.link = URL(string: Self.swapFirstHopUrl)
        part.font = TextStyle.captionSB.font
        part.foregroundColor = ColorStyle.yellow.color
        part.underlineStyle = .single

        return part
    }
}
