import SwiftUI

struct Informed: ViewModifier {
    let infoDescription: InfoDescription
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
        .bottomSheetNew(isPresented: $descriptionPresented) {
            BottomSheetView(
                icon: .info,
                title: infoDescription.title,
                items: [
                    .text(text: infoDescription.description),
                ],
                onDismiss: { descriptionPresented = false }
            )
        }
    }
}
