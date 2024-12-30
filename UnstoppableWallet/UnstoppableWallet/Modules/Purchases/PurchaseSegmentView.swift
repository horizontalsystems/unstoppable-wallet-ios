import SwiftUI

struct PurchaseSegmentView: View {
    @Binding var selection: PurchaseManager.SubscriptionType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PurchaseManager.SubscriptionType.allCases, id: \.self) { type in
                segmentButton(
                    title: type.rawValue.uppercased(),
                    icon: Image(type.icon),
                    isSelected: selection == type
                ) {
                    selection = type
                }
            }
        }
        .frame(height: 44)
        .background(Color(hex: 0x6E7899).opacity(0.2))
    }

    private func segmentButton(title: String, icon: Image, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .margin6) {
                icon
                    .renderingMode(.template)
                    .foregroundColor(isSelected ? .themeDarker : Color(hex: 0xFFA800))
                Text(title)
                    .textCaptionSB(color: isSelected ? .themeDarker : .themeGray)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 44)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: 0xFFD000),
                            Color(hex: 0xFFA800),
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.clear
                }
            }
        )
    }
}
