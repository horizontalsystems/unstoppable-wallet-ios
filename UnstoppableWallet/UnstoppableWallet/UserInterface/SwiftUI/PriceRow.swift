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
            ListRow {
                Text(title).textSubhead2()

                Spacer()

                Button(action: {
                    flipped.toggle()
                }) {
                    HStack(spacing: .margin8) {
                        Text(text)
                            .textSubhead1(color: .themeLeah)
                            .multilineTextAlignment(.trailing)

                        Image("arrow_swap_3_20").themeIcon()
                    }
                }
            }
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
