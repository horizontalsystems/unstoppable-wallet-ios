import SwiftUI

struct RowButtonStyle: ButtonStyle {
    @Environment(\.listStyle) var listStyle

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.themeLawrencePressed : listStyle.backgroundColor)
    }
}
