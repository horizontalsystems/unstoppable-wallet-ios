import SwiftUI

struct CellButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .modifier(Modifier(isPressed: configuration.isPressed))
    }

    private struct Modifier: ViewModifier {
        let isPressed: Bool

        func body(content: Content) -> some View {
            content.background(isPressed ? Color.themeBlade : Color.themeLawrence)
        }
    }
}
