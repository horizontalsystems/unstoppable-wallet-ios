import SwiftUI

struct SubscribePeriodView: View {
    let item: PurchaseProductItemFactory.Item
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: .heightOneDp) {
            HStack(spacing: .margin8) {
                ThemeText(item.title, style: .headline1)
                if let badge = item.discountBadge {
                    Text(badge)
                        .textMicroSB(color: .themeClaude)
                        .padding(.horizontal, .margin6)
                        .padding(.vertical, .margin2)
                        .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeRemus))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
                }
                Spacer()
            }
            HStack(spacing: .margin4) {
                ThemeText(item.price, style: .subheadR, colorStyle: .yellow)

                if let priceDescription = item.priceDescription {
                    ThemeText(priceDescription, style: .subheadR, colorStyle: .green)
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
}
