import SwiftUI

struct Informed: ViewModifier {
    let infoDescription: InfoDescription
    var horizontalPadding: CGFloat = 16

    func body(content: Content) -> some View {
        Button(action: {
            Coordinator.shared.present(type: .bottomSheet) { _ in
                BottomSheetView(
                    items: [
                        .title(icon: ThemeImage.book, title: infoDescription.title),
                        .text(text: infoDescription.description),
                    ],
                )
            }
        }, label: {
            HStack(spacing: 8) {
                content
                ThemeImage("info_filled", size: 20)
            }
            .padding(.horizontal, horizontalPadding)
        })
    }
}
