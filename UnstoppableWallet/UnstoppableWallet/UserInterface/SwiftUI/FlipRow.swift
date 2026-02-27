import Foundation
import MarketKit
import SwiftUI

protocol IFlippedData {
    func text(flipped: Bool) -> String?
}

struct FlipRow: View {
    let title: CustomStringConvertible
    let flipData: IFlippedData

    @State private var flipped = false

    var body: some View {
        if let text = flipData.text(flipped: flipped) {
            let infoDescription = (title as? SendField.InformedTitle)?.info
            Cell(
                style: .secondary,
                middle: {
                    if let infoDescription {
                        MiddleTextIcon(text: title)
                            .modifier(Informed(infoDescription: infoDescription, horizontalPadding: 0))
                    } else {
                        MiddleTextIcon(text: title)
                    }
                },
                right: {
                    RightMultiText(subtitle: ComponentText(text: text, colorStyle: .primary))
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
}

extension FlipRow {
    struct TokenPriceData: IFlippedData {
        let tokenA: Token
        let tokenB: Token
        let amountA: Decimal
        let amountB: Decimal

        func text(flipped: Bool) -> String? {
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

    struct TokenFeeData: IFlippedData {
        let amountData: AmountData?
        var formatFull: Bool = true

        func text(flipped: Bool) -> String? {
            let appValueFormatted = (formatFull ? amountData?.appValue.formattedFull() : amountData?.appValue.formattedShort()) ?? "n/a".localized

            guard let currencyValue = amountData?.currencyValue else {
                return appValueFormatted
            }

            let currencyValueFormatted = formatFull ? currencyValue.formattedFull : currencyValue.formattedShort

            return flipped ? currencyValueFormatted : appValueFormatted
        }
    }
}
