import SwiftUI

struct TabHeaderView: View {
    let tabs: [String]

    @Binding var currentTabIndex: Int
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    let isActive = index == currentTabIndex

                    ThemeText(
                        tabs[index],
                        style: isActive ? .subheadSB : .subhead,
                        colorStyle: isActive ? .primary : .secondary
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        currentTabIndex = index
                    }
                }
            }
            .frame(maxWidth: .infinity)

            GeometryReader { geo in
                Rectangle()
                    .fill(Color.themeJacob)
                    .frame(height: 2)
                    .frame(width: geo.size.width / CGFloat(tabs.count))
                    .offset(x: offset, y: 0)
                    .onChange(of: currentTabIndex) { index in
                        withAnimation(.spring().speed(1.5)) {
                            offset = geo.size.width / CGFloat(tabs.count) * CGFloat(index)
                        }
                    }
                    .onAppear {
                        offset = geo.size.width / CGFloat(tabs.count) * CGFloat(currentTabIndex)
                    }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, .margin12)
        .frame(height: 52)
        .background(Color.themeTyler)
    }
}
