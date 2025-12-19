import Foundation
import MarketKit
import SwiftUI

struct PriceRow: View {
    let title: String
    let tokenA: Token
    let tokenB: Token
    let amountA: Decimal
    let amountB: Decimal

    @State private var flipped = false

    var body: some View {
        if let text {
            Cell(
                style: .secondary,
                middle: {
                    MiddleTextIcon(text: title)
                },
                right: {
                    RightTextIcon(text: text)
                        .id(text)
                        .transition(.opacity)
                        .onTapGesture {
                            flipped.toggle()
                        }
                }
            )
            .animation(.easeInOut(duration: 0.15), value: text)
        }
    }

    private var text: String? {
        var showAsIn = amountA < amountB

        if flipped {
            showAsIn.toggle()
        }

        let _tokenA = showAsIn ? tokenA : tokenB
        let _tokenB = showAsIn ? tokenB : tokenA
        let _amountA = showAsIn ? amountA : amountB
        let _amountB = showAsIn ? amountB : amountA

        let formattedValue = ValueFormatter.instance.formatFull(value: _amountB / _amountA, decimalCount: _tokenB.decimals)
        return formattedValue.map { "1 \(_tokenA.coin.code) = \($0) \(_tokenB.coin.code)" }
    }
}
