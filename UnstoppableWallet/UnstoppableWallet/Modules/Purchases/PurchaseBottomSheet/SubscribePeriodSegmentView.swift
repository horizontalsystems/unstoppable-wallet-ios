import SwiftUI

struct SubscribePeriodSegmentView: View {
    let type: PurchaseManager.SubscriptionType

    @Binding var selection: PurchaseManager.SubscriptionPeriod

    var body: some View {
        VStack(spacing: 12) {
            ForEach(PurchaseManager.SubscriptionPeriod.allCases, id: \.self) { period in
                let viewItem = PurchaseBottomSheetViewModel.ViewItem(type: type, period: period)

                segmentButton(
                    title: viewItem.title,
                    badge: viewItem.discountBadge,
                    price: viewItem.price,
                    priceDescription: viewItem.priceDescription,
                    isSelected: selection == period,
                    action: {
                        selection = period
                        print("TAP on \(period.rawValue)")
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
                        .textMicroSB(color: .themeClaude)
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
        .onTapGesture(perform: action)
    }
}
