import SwiftUI

struct CloudNotAvailableView: View {
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            icon: .local(name: "icloud_24", tint: .themeJacob),
            title: "backup.cloud.no_access.title".localized,
            items: [
                .highlightedDescription(text: "backup.cloud.no_access.description".localized),
            ],
            buttons: [
                .init(style: .yellow, title: "button.ok".localized) {
                    isPresented = false
                },
            ],
            isPresented: $isPresented
        )
    }
}
