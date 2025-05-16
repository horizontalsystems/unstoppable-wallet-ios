import SwiftUI

struct SubscribePeriodSegmentView: View {
    @Binding var items: [PurchaseBottomSheetViewModel.Item]
    @Binding var selection: PurchaseBottomSheetViewModel.Item?

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

    private func segmentButton(title: String, badge: String?, price: String, priceDescription: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: .heightOneDp) {
            HStack(spacing: .margin8) {
                Text(title).textHeadline1()
                if let badge {
                    Text(badge)
                        .textMicroSB(color: .themeLawrence)
                        .padding(.horizontal, .margin6)
                        .padding(.vertical, .margin2)
                        .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeRemus))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
                }
                Spacer()
            }
            HStack(spacing: .margin4) {
                Text(price).textSubhead2(color: .themeJacob)

                if let priceDescription {
                    Text(priceDescription)
                        .textSubhead2(color: .themeRemus)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin12)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                .strokeBorder(isSelected ? Color.themeJacob : Color.themeSteel20, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
