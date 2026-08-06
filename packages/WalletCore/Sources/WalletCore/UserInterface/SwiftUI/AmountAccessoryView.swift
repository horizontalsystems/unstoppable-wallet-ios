import SwiftUI

struct AmountAccessoryView: View {
    private let height: CGFloat = 52

    let visible: Bool
    let enabledPercents: Bool
    let onPercent: (Int) -> Void
    let onTrash: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                HStack(spacing: 12) {
                    ForEach(1 ... 4, id: \.self) { multiplier in
                        let percent = multiplier * 25

                        ThemeButton(text: percent == 100 ? "send.max_button".localized : "\(percent)%", style: .secondary, size: .small) {
                            onPercent(percent)
                        }
                    }
                }
                .disabled(!enabledPercents)

                Spacer()

                IconButton(icon: "trash", style: .secondary, size: .small) {
                    onTrash()
                }
            }
            .padding(.horizontal, 16)
            .frame(height: height)
            .offset(y: visible ? 0 : height)
        }
        .frame(height: visible ? height : 0)
    }
}
