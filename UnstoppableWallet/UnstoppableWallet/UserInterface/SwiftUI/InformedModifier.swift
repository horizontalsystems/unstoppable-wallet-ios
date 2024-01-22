import SwiftUI

struct Informed: ViewModifier {
    private let description: AlertView.InfoDescription
    @State private var descriptionPresented: Bool = false

    init(description: AlertView.InfoDescription) {
        self.description = description
    }

    func body(content: Content) -> some View {
        Button(action: {
            descriptionPresented = true
        }, label: {
            content
        })
        .buttonStyle(SecondaryButtonStyle(style: .transparent, rightAccessory: .info))
        .bottomSheet(isPresented: $descriptionPresented) {
            AlertView(
                image: .info,
                title: description.title,
                items: [
                    .description(text: description.description),
                ],
                onDismiss: { descriptionPresented = false }
            )
        }
    }
}
