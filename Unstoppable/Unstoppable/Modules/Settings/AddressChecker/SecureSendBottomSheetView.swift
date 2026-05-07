import SwiftUI

struct SecureSendBottomSheetView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSModule.view(for: .title(title: "secure_send.bottom_sheet.title".localized))
                BSModule.view(for: .text(text: "secure_send.bottom_sheet.description".localized))

                ListSection {
                    AddressSecurityTypeContentView()
                        .padding(.vertical, .margin8)
                }
                .themeListStyle(.bordered)

                BSModule.view(for: .buttonGroup(.init(buttons: [
                    .init(
                        style: .yellow,
                        title: "button.done".localized,
                        action: {
                            $isPresented.wrappedValue = false
                        }
                    ),
                ])))
            }
        }
    }
}
