import SwiftUI

struct SwapHistoryListView: View {
    @ObservedObject var viewModel: SwapHistoryViewModel
    let emptyText: String

    var body: some View {
        if !viewModel.isLoaded {
            Color.clear
        } else if viewModel.sections.isEmpty {
            PlaceholderViewNew(icon: "outgoingraw", subtitle: emptyText)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(TestTags.activityEmpty)
        } else {
            ThemeList(bottomSpacing: .margin16) {
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.viewItems) { viewItem in
                            ActivityCellView(viewItem: viewItem.cell, isLast: viewItem.id == section.viewItems.last?.id) {
                                let swap = viewModel.correctedSwap(viewItem.swap)

                                Coordinator.shared.present { isPresented in
                                    SwapInfoView(swap: swap)
                                        .closeNavigation(isPresented: isPresented)
                                }
                            }
                            .accessibilityIdentifier(TestTags.activityItem(viewItem.swap.uid))
                            .onAppear {
                                viewModel.onDisplay(viewItem: viewItem)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        ThemeListSectionHeader(text: section.title)
                    }
                    .listSectionSeparator(.hidden)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}
