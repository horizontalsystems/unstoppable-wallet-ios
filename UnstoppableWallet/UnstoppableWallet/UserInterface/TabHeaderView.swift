import SwiftUI

struct TabHeaderView: View {
    let tabs: [String]

    @Binding var currentTabIndex: Int
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color.themeSteel10)
                .frame(maxWidth: .infinity)
                .frame(height: 1)

            ZStack(alignment: .bottom) {
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Button(action: {
                            currentTabIndex = index
                        }) {
                            Text(tabs[index])
                        }
                        .buttonStyle(TabButtonStyle(isActive: index == currentTabIndex))
                    }
                }
                .frame(maxWidth: .infinity)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.themeJacob)
                        .frame(height: 4)
                        .frame(width: geo.size.width / CGFloat(tabs.count))
                        .offset(x: offset, y: 0)
                        .onChange(of: currentTabIndex) { index in
                            withAnimation(.spring().speed(1.5)) {
                                offset = geo.size.width / CGFloat(tabs.count) * CGFloat(index)
                            }
                        }
                }
                .frame(height: 2)
            }
            .padding(.horizontal, .margin12)
        }
        .frame(height: 44)
        .clipped()
    }
}
