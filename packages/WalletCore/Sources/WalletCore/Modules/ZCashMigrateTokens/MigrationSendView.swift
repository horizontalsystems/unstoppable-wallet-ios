import SwiftUI

struct MigrationSendView: View {
    private let sendData: SendData = .zcashMigration

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ThemeView {
            RegularSendView(sendData: sendData) {
                HudHelper.instance.show(banner: .sent)
                presentationMode.wrappedValue.dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("close")
                }
            }
        }
    }
}
