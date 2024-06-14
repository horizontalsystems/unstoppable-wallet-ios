import SwiftUI

struct CoinHoldersChart: View {
    let items: [(Decimal, Color)]

    private let spacing: CGFloat = 1

    var body: some View {
        let count = CGFloat(items.count)

        GeometryReader { proxy in
            HStack(spacing: spacing) {
                ForEach(items.indices, id: \.self) { index in
                    let (percent, color) = items[index]
                    let doublePercent = (percent as NSDecimalNumber).doubleValue

                    RoundedRectangle(cornerRadius: .cornerRadius2, style: .continuous)
                        .fill(color)
                        .frame(width: (proxy.size.width - (count - 1) * spacing) * doublePercent)
                }
            }
        }
        .frame(height: 40)
    }
}
