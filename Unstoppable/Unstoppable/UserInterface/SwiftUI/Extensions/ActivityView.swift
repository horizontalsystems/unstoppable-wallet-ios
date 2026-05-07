import SwiftUI
import UIKit

struct ActivityView: View {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil

    var body: some View {
        ActivityViewInternal(activityItems: activityItems, applicationActivities: applicationActivities, completionWithItemsHandler: completionWithItemsHandler)
            .presentationDetents([.medium, .large])
    }
}

struct ActivityViewInternal: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil

    func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityViewInternal>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = completionWithItemsHandler
        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityViewInternal>) {}
}
