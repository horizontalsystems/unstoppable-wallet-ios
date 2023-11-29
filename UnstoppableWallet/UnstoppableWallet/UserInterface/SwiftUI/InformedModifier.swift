import SwiftUI

struct Informed: ViewModifier {
    private let description: AlertView.InfoDescription
    @State private var descriptionPresented: Bool = false

    init(description: AlertView.InfoDescription) {
        self.description = description
    }

    func body(content: Content) -> some View {
        HStack(spacing: .margin8) {
            content

            Button(action: {
                descriptionPresented = true
            }, label: {
                Image("circle_information_20").renderingMode(.template)
            })
            .buttonStyle(SecondaryCircleButtonStyle(style: .transparent))
        }
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
