import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil

    func makeUIViewController(context _: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = completionWithItemsHandler
        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: UIViewControllerRepresentableContext<ActivityView>) {}
}

extension ActivityView {
    static func view(activityItems: [Any], applicationActivities: [UIActivity]? = nil, completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil) -> some View {
        let view = ActivityView(
            activityItems: activityItems,
            applicationActivities: applicationActivities,
            completionWithItemsHandler: completionWithItemsHandler
        )
        if #available(iOS 16, *) {
            return view
                .presentationDetents([.medium, .large])
                .toolbarBackground(.visible, for: .navigationBar)
                .ignoresSafeArea(edges: .bottom)
        } else {
            return view
        }
    }
}

extension URL: Identifiable {
    public var id: String {
        absoluteString
    }
}
