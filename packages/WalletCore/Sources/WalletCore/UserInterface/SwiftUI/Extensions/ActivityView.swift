import SwiftUI
import UIKit

public struct ActivityView: View {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil

    public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.completionWithItemsHandler = completionWithItemsHandler
    }

    public var body: some View {
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
