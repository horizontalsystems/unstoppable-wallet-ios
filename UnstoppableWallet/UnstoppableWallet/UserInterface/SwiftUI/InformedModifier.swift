import SwiftUI

struct Informed: ViewModifier {
    let infoDescription: InfoDescription

    func body(content: Content) -> some View {
        Button(action: {
            Coordinator.shared.present(type: .bottomSheet) { _ in
                BottomSheetView(
                    items: [
                        .title(icon: .book, title: infoDescription.title),
                        .text(text: infoDescription.description),
                    ],
                )
            }
        }, label: {
            HStack(spacing: .margin8) {
                content
                Image("circle_information_20").themeIcon()
            }
            .padding(EdgeInsets(top: 5.5, leading: .margin16, bottom: 5.5, trailing: .margin16))
        })
    }
}
