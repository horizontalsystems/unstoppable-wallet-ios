import SwiftUI
import ThemeKit

struct EducationView: View {
    @StateObject var viewModel = EducationViewModel()

    @State var currentTabIndex = 0

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case let .loaded(categories):
                VStack(spacing: 0) {
                    ScrollableTabHeaderView(
                        tabs: categories.map { $0.title },
                        currentTabIndex: $currentTabIndex
                    )

                    TabView(selection: $currentTabIndex) {
                        ForEach(categories.indices, id: \.self) { index in
                            SectionView(sections: categories[index].sections)
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
        .navigationBarTitle("education.title".localized)
    }
}

extension EducationView {
    struct SectionView: View {
        let sections: [EducationViewModel.Section]

        @State private var expandedIndices = Set<Int>()

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(sections.indices, id: \.self) { index in
                        let section = sections[index]
                        let expanded = expandedIndices.contains(index)
                        let last = index == sections.count - 1

                        VStack(spacing: 0) {
                            VStack(spacing: 0) {
                                HorizontalDivider()

                                HStack(spacing: .margin8) {
                                    Text(section.title).textHeadline2().multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(expanded ? "arrow_big_up_20" : "arrow_big_down_20")
                                }
                                .padding(.vertical, .margin12)
                                .padding(.horizontal, .margin16)
                            }
                            .zIndex(2)
                            .background(Color.themeLawrence)
                            .onTapGesture {
                                withAnimation {
                                    if expandedIndices.contains(index) {
                                        expandedIndices.remove(index)
                                    } else {
                                        expandedIndices.insert(index)
                                    }
                                }
                            }

                            if expanded {
                                ListSection {
                                    ForEach(section.items.indices, id: \.self) { index in
                                        let item = section.items[index]

                                        NavigationRow {
                                            ThemeNavigationView {
                                                MarkdownView(url: item.url).ignoresSafeArea()
                                            }
                                            .ignoresSafeArea()
                                            .onFirstAppear {
                                                stat(page: .education, event: .openArticle(relativeUrl: item.url.relativePath))
                                            }
                                        } content: {
                                            Text(item.title).themeBody()
                                        }
                                    }
                                }
                                .themeListStyle(last ? .transparent : .transparentInline)
                                .zIndex(1)
                                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .clipped()
                    }
                }
                .padding(.bottom, .margin16)
            }
        }
    }
}
