import SwiftUI

struct SelectorButtonStyle: ButtonStyle {
    let count: Int
    let selectedIndex: Int

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .margin2) {
            configuration.label
                .font(.themeCaptionSB)
                .foregroundColor(isEnabled ? (configuration.isPressed ? .themeGray : .themeLeah) : .themeGray50)

            VStack(spacing: count == 2 ? 4 : 2) {
                ForEach(0 ..< count, id: \.self) { index in
                    if index == selectedIndex {
                        Circle()
                            .fill(Color.themeGray)
                            .frame(width: 4, height: 4)

                    } else {
                        Circle()
                            .strokeBorder(Color.themeGray, lineWidth: 1)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(width: .iconSize20, height: .iconSize20)
        }
        .padding(.leading, .margin16)
        .padding(.trailing, .margin12)
        .frame(height: 28)
        .background(isEnabled ? (configuration.isPressed ? Color.themeBlade : Color.themeBlade) : Color.themeBlade)
        .clipShape(Capsule(style: .continuous))
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SelectorButtonInfo: Equatable {
    let text: String
    let count: Int
    let selectedIndex: Int
}
