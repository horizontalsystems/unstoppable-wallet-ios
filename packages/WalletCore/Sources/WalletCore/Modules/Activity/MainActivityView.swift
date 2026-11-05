import SwiftUI

struct MainActivityView: View {
    let viewModel: ActivityViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ContentView(viewModel: viewModel, transactionsViewModel: viewModel.transactionsViewModel, isPresented: $isPresented)
    }
}

extension MainActivityView {
    private struct ContentView: View {
        @ObservedObject var viewModel: ActivityViewModel
        @ObservedObject var transactionsViewModel: TransactionsViewModel
        @Binding var isPresented: Bool

        var body: some View {
            ThemeNavigationStack {
                ThemeView(style: .list) {
                    VStack(spacing: 0) {
                        ScrollableTabHeaderView(
                            tabs: ActivityTab.allCases.map {
                                .init(title: $0.title, highlighted: false, accessibilityIdentifier: TestTags.activityTab($0.rawValue))
                            },
                            currentTabIndex: Binding(
                                get: {
                                    ActivityTab.allCases.firstIndex(of: viewModel.selectedTab) ?? 0
                                },
                                set: { index in
                                    viewModel.selectedTab = ActivityTab.allCases[index]
                                }
                            )
                        )

                        content(tab: viewModel.selectedTab)
                    }
                }
                .navigationBarTitle("activity.title".localized)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image("close")
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            Coordinator.shared.present { isPresented in
                                TransactionFilterView(transactionsViewModel: transactionsViewModel, isPresented: isPresented)
                            }
                            stat(page: .transactions, event: .open(page: .transactionFilter))
                        }) {
                            Image("manage")
                                .modifier(ToolbarBadgeModifier(visible: transactionsViewModel.filterChanged))
                        }
                        .accessibilityIdentifier(TestTags.txFilter)
                    }
                }
            }
        }

        @ViewBuilder private func content(tab: ActivityTab) -> some View {
            if let swapHistoryViewModel = viewModel.swapHistoryViewModel(for: tab) {
                SwapHistoryListView(viewModel: swapHistoryViewModel, emptyText: tab.emptyText)
            } else if transactionsViewModel.sections.isEmpty {
                PlaceholderViewNew(icon: "outgoingraw", subtitle: tab.emptyText)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier(TestTags.txEmpty)
            } else {
                ThemeList(bottomSpacing: .margin16) {
                    TransactionsView(viewModel: transactionsViewModel, statPage: .transactions)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}
