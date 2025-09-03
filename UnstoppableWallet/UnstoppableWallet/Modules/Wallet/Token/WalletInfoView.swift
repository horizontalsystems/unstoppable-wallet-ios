import Foundation
import SwiftUI

enum WalletInfoView {
    @ViewBuilder static func infoView(title: String, value: ValueFormatStyle, action: (() -> Void)?) -> some View {
        Cell(
            middle: {
                MiddleTextIcon(text: title, icon: "info_filled")
            },
            right: {
                RightTextIcon(
                    text: ComponentText(
                        text: value.formatted,
                        colorStyle: .primary
                    )
                )
            },
            action: action
        )
    }

    @ViewBuilder static func infoView(title: String, info: InfoDescription, value: ValueFormatStyle) -> some View {
        infoView(title: title, value: value, action: {
            Coordinator.shared.present(info: info)
        })
    }

    enum ValueFormatStyle {
        case hiddenAmount
        case fullAmount(AppValue)

        var formatted: String {
            switch self {
            case .hiddenAmount: return BalanceHiddenManager.placeholder
            case let .fullAmount(appValue):
                return ValueFormatter.instance.formatFull(value: appValue.value, decimalCount: appValue.decimals ?? 8, symbol: appValue.code) ?? .placeholder
            }
        }
    }
}
