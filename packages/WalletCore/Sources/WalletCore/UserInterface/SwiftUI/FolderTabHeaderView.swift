import SwiftUI

// Horizontally scrollable tab header where the active tab is drawn as a folder tab that merges into the
// content below. The header sits on a Tyler background and the content is expected to be Lawrence.
struct FolderTabHeaderView: View {
    private let tabs: [Tab]

    @Binding var currentTabIndex: Int

    init(tabs: [Tab], currentTabIndex: Binding<Int>) {
        self.tabs = tabs
        _currentTabIndex = currentTabIndex
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { index in
                        item(tab: tabs[index], isActive: index == currentTabIndex)
                            .id(index)
                            .onTapGesture {
                                currentTabIndex = index
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: currentTabIndex) { _, index in
                proxy.scrollTo(index, anchor: .center)
            }
            .onFirstAppear {
                proxy.scrollTo(currentTabIndex, anchor: .center)
            }
        }
        .padding(.top, 8)
        .background(Color.themeTyler)
    }

    @ViewBuilder private func item(tab: Tab, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            if let icon = tab.icon {
                ThemeImage(icon, size: 16, colorStyle: isActive ? .primary : .secondary)
            }

            ThemeText(tab.title, style: isActive ? .subheadSB : .subhead, colorStyle: isActive ? .primary : .secondary)
        }
        .padding(.leading, isActive ? 16 : 12)
        .padding(.trailing, isActive ? 28 : 12)
        .padding(.vertical, 12)
        .background {
            if isActive {
                FolderTabShape(slantWidth: 12)
                    .fill(Color.themeLawrence)
            }
        }
        .contentShape(Rectangle())
    }
}

extension FolderTabHeaderView {
    struct Tab {
        let title: String
        let icon: String?

        init(title: String, icon: String? = nil) {
            self.title = title
            self.icon = icon
        }
    }
}

// Rounded top-left corner, rounded top-right corner and a slanted right edge running down to the bottom.
private struct FolderTabShape: Shape {
    let slantWidth: CGFloat
    var cornerRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let topRight = CGPoint(x: rect.maxX - slantWidth, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        let slant = CGVector(dx: bottomRight.x - topRight.x, dy: bottomRight.y - topRight.y)
        let slantLength = sqrt(slant.dx * slant.dx + slant.dy * slant.dy)
        let slantStart = CGPoint(
            x: topRight.x + slant.dx / slantLength * cornerRadius,
            y: topRight.y + slant.dy / slantLength * cornerRadius
        )

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: topRight.x - cornerRadius, y: rect.minY))
        path.addQuadCurve(to: slantStart, control: topRight)
        path.addLine(to: bottomRight)
        path.closeSubpath()
        return path
    }
}
