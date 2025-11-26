import SwiftUI

struct SubscribePeriodSegmentView: View {
    @Binding var items: [PurchaseProductItemFactory.Item]
    @Binding var selection: PurchaseProductItemFactory.Item?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(items, id: \.self) { item in
                segmentButton(
                    title: item.title,
                    badge: item.discountBadge,
                    price: item.price,
                    priceDescription: item.priceDescription,
                    isSelected: selection == item,
                    action: {
                        selection = item
                    }
                )
            }
        }
    }

    private func segmentButton(title: CustomStringConvertible, badge: String?, price: CustomStringConvertible, priceDescription: CustomStringConvertible?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: .heightOneDp) {
            HStack(spacing: .margin8) {
                ThemeText(title, style: .headline1)
                if let badge {
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
                ThemeText(price, style: .subheadR, colorStyle: .yellow)

                if let priceDescription {
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
