import SwiftUI

typealias TabBarBadgeIndex = Int

extension TabBarBadgeIndex {
    static let last = -1
    static let first = 0
}

struct TabBarBadgeOverlay: View {
    @ObservedObject var frameCalculator: TabBarFrameCalculator
    let badgeText: String?
    let targetTabIndex: TabBarBadgeIndex

    var body: some View {
        if let badgeText,
           frameCalculator.isCalculated,
           let badgePosition = frameCalculator.getBadgePosition(for: targetTabIndex)
        {
            VStack {
                HStack {
                    CustomBadgeView(badge: badgeText)
                        .position(x: badgePosition.x, y: badgePosition.y)
                }
            }
            .allowsHitTesting(false)
        }
    }
}

struct CustomBadgeView: View {
    let emptyBadgeSize: CGFloat = 10
    let badge: String?

    var body: some View {
        if let badge {
            if badge.isEmpty {
                Circle()
                    .foregroundStyle(Color.themeRed)
                    .frame(width: emptyBadgeSize, height: emptyBadgeSize)
            } else {
                Text(badge)
                    .font(.themeMicro)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.themeRed)
                    .clipShape(Capsule())
            }
        } else {
            EmptyView()
        }
    }
}
