import Combine
import UIKit

class TabBarFrameCalculator: ObservableObject {
    @Published var tabFrames: [TabFrameInfo] = []
    @Published var tabBarFrame: CGRect = .zero
    @Published var isCalculated = false

    func calculateFrames() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController as? UIViewController
        else {
            return
        }

        guard let tabBarController = ThemeTabBarController.find(viewController: rootViewController) else {
            return
        }

        let tabBar = tabBarController.tabBar
        tabBarFrame = tabBar.frame

        let navigationBarHeight = tabBarController.navigationController?.navigationBar.frame.maxY ?? 0

        var frames: [TabFrameInfo] = []

        let tabBarButtons = tabBar.subviews.compactMap { $0 as? UIControl }
            .filter { String(describing: type(of: $0)).contains("UITabBarButton") }
            .sorted { $0.frame.minX < $1.frame.minX }

        for (index, button) in tabBarButtons.enumerated() {
            let imageFrame = button
                .subviews
                .first { subview in
                    String(describing: type(of: subview)).contains("UITabBarSwappableImageView")
                }?.frame ?? CGRect(x: 0, y: 0, width: TabFrameInfo.badgeSize, height: TabFrameInfo.badgeSize)

            var correctedButtonFrame = button.frame
            correctedButtonFrame.origin.y = tabBarFrame.minY - navigationBarHeight + button.frame.minY

            let frameInfo = TabFrameInfo(
                index: index,
                frame: correctedButtonFrame,
                imageFrame: imageFrame
            )

            frames.append(frameInfo)
        }

        DispatchQueue.main.async {
            self.tabFrames = frames
            self.isCalculated = true
        }
    }

    func getBadgePosition(for tabIndex: TabBarBadgeIndex) -> CGPoint? {
        guard !tabFrames.isEmpty else {
            return nil
        }

        let frameInfo: TabFrameInfo?
        switch tabIndex {
        case .last: frameInfo = tabFrames.last
        default:
            guard tabIndex < tabFrames.count else { return nil }
            frameInfo = tabFrames[tabIndex]
        }

        return frameInfo.map(\.badgePosition)
    }
}

struct TabFrameInfo {
    static let badgeSize = CGFloat.iconSize24
    static let badgeOffset = CGPoint(x: badgeSize / 2, y: -badgeSize / 2)

    let index: Int
    let frame: CGRect
    let imageFrame: CGRect

    var badgePosition: CGPoint {
        CGPoint(
            x: frame.midX + Self.badgeOffset.x,
            y: frame.midY + Self.badgeOffset.y
        )
    }
}
