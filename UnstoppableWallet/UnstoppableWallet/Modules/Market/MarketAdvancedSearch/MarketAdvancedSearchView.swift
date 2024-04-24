import SwiftUI
import ThemeKit

struct MarketAdvancedSearchView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        ThemeNavigationController(rootViewController: MarketAdvancedSearchModule.viewController())
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
