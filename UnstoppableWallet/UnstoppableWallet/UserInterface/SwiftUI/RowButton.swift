import SwiftUI

struct RowButton: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
                .background(configuration.isPressed ? Color.themeLawrencePressed : Color.themeLawrence)
    }

}
