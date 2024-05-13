import MarketKit
import SwiftUI
import UIKit

struct MarketPlatformView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let platform: TopPlatform

    func makeUIViewController(context _: Context) -> UIViewController {
        TopPlatformModule.viewController(topPlatform: platform)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
