import MessageUI
import SwiftUI

public struct MailView: UIViewControllerRepresentable {
    private let recipient: String
    private let body: String
    @Binding private var isPresented: Bool

    public init(recipient: String, body: String, isPresented: Binding<Bool>) {
        self.recipient = recipient
        self.body = body
        _isPresented = isPresented
    }

    public class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        public func mailComposeController(_: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            isPresented = false
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let viewController = MFMailComposeViewController()
        viewController.mailComposeDelegate = context.coordinator
        viewController.setToRecipients([recipient])
        viewController.setMessageBody(body, isHTML: false)
        return viewController
    }

    public func updateUIViewController(_: MFMailComposeViewController, context _: UIViewControllerRepresentableContext<MailView>) {}
}
