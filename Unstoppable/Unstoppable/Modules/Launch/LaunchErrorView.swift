import MessageUI
import SwiftUI

struct LaunchErrorView: View {
    let error: Error

    @State private var mailPresented = false

    var body: some View {
        ThemeView {
            VStack(spacing: .margin32) {
                Image("attention_48").themeIcon()

                Text("launch.failed_to_launch".localized)
                    .textBody(color: .themeGray)
                    .multilineTextAlignment(.center)

                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        mailPresented = true
                    } else {
                        CopyHelper.copyAndNotify(value: errorString)
                    }
                }) {
                    Text("launch.failed_to_launch.report".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .gray))
            }
            .padding(.horizontal, .margin48)
        }
        .sheet(isPresented: $mailPresented) {
            MailView(
                recipient: AppConfig.reportEmail,
                body: errorString,
                isPresented: $mailPresented
            )
        }
    }

    var errorString: String {
        """
        Raw Error: \(error)
        Localized Description: \(error.localizedDescription)
        """
    }
}
