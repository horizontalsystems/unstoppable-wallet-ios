import SwiftUI

struct BlackFridaySubscribePeriodView: View {
    let item: BlackFridayPurchaseProductItemFactory.Item
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: .heightOneDp) {
            HStack(spacing: .margin8) {
                ThemeText(item.title, style: .headline1)
                if let badge = item.discountBadge {
                    badgeView(badge)
                }
                Spacer()
            }
            HStack(spacing: .margin4) {
                ThemeText(item.price, style: .subheadR, colorStyle: .yellow)

                if let priceDescription = item.attributedDescription {
                    ThemeText(priceDescription, style: .subheadR)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin12)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                .strokeBorder(isSelected ? Color.themeJacob : Color.themeBlade, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    @ViewBuilder
    private func badgeView(_ text: String) -> some View {
        switch item.badgeType {
        case .standart:
            ThemeText(text, style: .microSB, colorStyle: .lawrence)
                .padding(.horizontal, .margin6)
                .padding(.vertical, .margin2)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous)
                        .fill(Color.themeRemus)
                )
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))

        case .blackFriday:
            ThemeText(text, style: .microSB)
                .padding(.horizontal, .margin6)
                .padding(.vertical, .margin2)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: 0xFFAA00),
                                    Color(hex: 0xFE4A11),
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
        }
    }
}
