import SwiftUI

struct SecureSendBottomSheetView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSModule.view(for: .title(title: "secure_send.bottom_sheet.title".localized))
                BSModule.view(for: .text(text: "secure_send.bottom_sheet.description".localized))

                AddressSecurityTypeContentView()
                    .padding(.vertical, .margin8)
                    .modifier(ThemeListStyleModifier(themeListStyle: .bordered))
                    .padding(EdgeInsets(top: .margin8, leading: .margin16, bottom: .margin24, trailing: .margin16))

                BSModule.view(for: .buttonGroup(.init(buttons: [
                    .init(
                        style: .primary,
                        title: "button.done".localized,
                        identifier: TestTags.secureSendDone,
                        action: {
                            $isPresented.wrappedValue = false
                        }
                    ),
                ])))
            }
        }
    }
}
