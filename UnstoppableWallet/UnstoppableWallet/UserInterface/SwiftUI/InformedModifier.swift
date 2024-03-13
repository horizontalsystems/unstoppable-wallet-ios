import SwiftUI

struct Informed: ViewModifier {
    let description: AlertView.InfoDescription
    @State private var descriptionPresented: Bool = false

    func body(content: Content) -> some View {
        Button(action: {
            descriptionPresented = true
        }, label: {
            HStack(spacing: .margin8) {
                content
                Image("circle_information_20").themeIcon()
            }
            .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
        })
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
