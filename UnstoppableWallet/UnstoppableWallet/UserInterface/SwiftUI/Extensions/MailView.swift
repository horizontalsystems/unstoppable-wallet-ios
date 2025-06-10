import MessageUI
import SwiftUI

struct MailView: UIViewControllerRepresentable {
    let recipient: String
    let body: String
    @Binding var isPresented: Bool

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func mailComposeController(_: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients([recipient])
        viewController.setMessageBody(body, isHTML: false)
        return viewController
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: UIViewControllerRepresentableContext<MailView>) {}
}
