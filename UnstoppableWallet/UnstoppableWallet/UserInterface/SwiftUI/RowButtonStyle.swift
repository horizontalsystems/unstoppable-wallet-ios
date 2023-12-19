import SwiftUI

struct RowButtonStyle: ButtonStyle {
    @Environment(\.themeListStyle) var listStyle

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .modifier(ThemeListStyleButtonModifier(themeListStyle: listStyle, isPressed: configuration.isPressed))
    }
}
