import MessageUI
import SwiftUI
import UserInterface

struct LaunchErrorView: View {
    let error: Error

    @State private var mailPresented = false

    var body: some View {
        ThemeView {
            VStack(spacing: 32) {
                ThemeImage("warning", size: 48)

                ThemeText(key: "launch.failed_to_launch", style: .body, color: .themeGray)
                    .multilineTextAlignment(.center)

                ThemeButton(text: "launch.failed_to_launch.report") {
                    if MFMailComposeViewController.canSendMail() {
                        mailPresented = true
                    } else {
                        CopyHelper.copyAndNotify(value: errorString)
                    }
                }
            }
            .padding(.horizontal, 48)
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
