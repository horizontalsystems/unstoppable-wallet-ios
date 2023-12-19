import SwiftUI

struct SelectorButtonStyle: ButtonStyle {
    let count: Int
    let selectedIndex: Int

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .margin4) {
            configuration.label
                .font(.themeSubhead1)
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
        .padding(EdgeInsets(top: .margin4, leading: .margin16, bottom: .margin4, trailing: .margin12))
        .background(isEnabled ? (configuration.isPressed ? Color.themeSteel10 : Color.themeSteel20) : Color.themeSteel20)
        .clipShape(Capsule(style: .continuous))
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SelectorButtonInfo: Equatable {
    let text: String
    let count: Int
    let selectedIndex: Int
}
