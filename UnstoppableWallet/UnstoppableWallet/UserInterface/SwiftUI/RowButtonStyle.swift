import SwiftUI

struct RowButtonStyle: ButtonStyle {
    @Environment(\.listStyle) var listStyle

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .modifier(ListStyleButtonModifier(listStyle: listStyle, isPressed: configuration.isPressed))
    }
}
