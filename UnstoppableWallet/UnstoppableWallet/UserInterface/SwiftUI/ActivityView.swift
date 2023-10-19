import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let text: String

    func makeUIViewController(context _: Context) -> UIViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
