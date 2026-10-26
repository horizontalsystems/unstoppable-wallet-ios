import SwiftUI

struct FaqView: View {
    @StateObject private var viewModel = FaqViewModel()

    @State private var currentTabIndex = 0

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(sections):
                VStack(spacing: 0) {
                    ScrollableTabHeaderView(
                        tabs: sections.map(\.title),
                        currentTabIndex: $currentTabIndex
                    )

                    TabView(selection: $currentTabIndex) {
                        ForEach(sections.indexedElements) { section in
                            SectionView(items: section.element.items)
                                .tag(section.index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(edges: .bottom)
                }
            case .failed:
                SyncErrorView {
                    viewModel.onRetry()
                }
            }
        }
        .navigationTitle("faq.title".localized)
    }
}

extension FaqView {
    private struct SectionView: View {
        let items: [FaqViewModel.Item]

        var body: some View {
            ScrollView {
                ListSection {
                    ForEach(items.indexedElements) { indexedItem in
                        let item = indexedItem.element

                        if let url = item.url {
                            NavigationRow(destination: {
                                MarkdownView(url: url, handleRelativeUrl: false)
                                    .onFirstAppear {
                                        stat(page: .faq, event: .openArticle(relativeUrl: url.relativePath))
                                    }
                            }) {
                                ThemeText(item.text, style: .subhead, colorStyle: .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image.disclosureIcon
                            }
                        } else {
                            ListRow {
                                ThemeText(item.text, style: .subhead, colorStyle: .primary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
        }
    }
}
