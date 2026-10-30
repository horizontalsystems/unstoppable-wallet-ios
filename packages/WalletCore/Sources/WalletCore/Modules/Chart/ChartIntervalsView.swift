import SwiftUI

struct ChartIntervalsView: View {
    let titles: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .margin8) {
                    ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                        let selected = index == selectedIndex

                        ThemeButton(text: title, style: selected ? .primary : .secondary, mode: selected ? .solid : .transparent, size: .small) {
                            guard !selected else { return }
                            onSelect(index)
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, .margin16)
            }
            .onAppear {
                scroll(to: selectedIndex, proxy: proxy)
            }
            .onChange(of: selectedIndex) { index in
                withAnimation {
                    scroll(to: index, proxy: proxy)
                }
            }
        }
        .frame(height: .heightCell48)
    }

    private func scroll(to index: Int, proxy: ScrollViewProxy) {
        guard titles.indices.contains(index) else { return }
        proxy.scrollTo(index, anchor: .center)
    }
}
