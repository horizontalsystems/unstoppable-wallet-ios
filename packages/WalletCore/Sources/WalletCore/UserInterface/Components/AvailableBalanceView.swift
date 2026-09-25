import Foundation
import MarketKit
import SwiftUI

struct AvailableBalanceView: View {
    let balance: Decimal?
    let token: Token?
    let allAvailable: Bool
    let currentValue: Decimal?
    let onSelect: (Int) -> Void
    let onClear: () -> Void
    var percents: [Int] = [25, 50, 75]

    var body: some View {
        HStack(spacing: 8) {
            ThemeText("send.balance.available".localized(formattedValue ?? "------"), style: .caption, colorStyle: allAvailable ? .blue : .secondary)
                .onTapGesture {
                    if allAvailable {
                        onSelect(100)
                    }
                }

            Spacer()

            if currentValue != nil {
                ThemeText("send.balance.clear".localized, style: .caption, colorStyle: .blue)
                    .onTapGesture {
                        onClear()
                    }
            } else if !percents.isEmpty {
                let enabled = (balance ?? 0) > 0

                HStack(spacing: 16) {
                    ForEach(percents, id: \.self) { percent in
                        ThemeText("\(percent)%", style: .caption, colorStyle: enabled ? .blue : .andy)
                            .onTapGesture {
                                if enabled {
                                    onSelect(percent)
                                }
                            }
                    }
                }
            }
        }
    }

    private var formattedValue: String? {
        guard let balance, let token else {
            return nil
        }

        return AppValue(token: token, value: balance).formattedShort()
    }
}
