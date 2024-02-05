import MarketKit
import SwiftUI

struct CoinAnalyticsIssuesView: View {
    let viewItem: CoinAnalyticsViewModel.IssueBlockchainViewItem

    @Environment(\.presentationMode) private var presentationMode
    @State private var currentTabIndex: Int = Tab.tokenDetectors.rawValue

    @State private var tokenExpandedIndices = Set<Int>()
    @State private var generalExpandedIndices = Set<Int>()

    var body: some View {
        ThemeView {
            VStack(spacing: 0) {
                TabHeaderView(
                    tabs: Tab.allCases.map(\.title),
                    currentTabIndex: $currentTabIndex
                )

                TabView(selection: $currentTabIndex) {
                    DetectorsView(items: viewItem.coreItems, expandedIndices: $tokenExpandedIndices).tag(Tab.tokenDetectors.rawValue)
                    DetectorsView(items: viewItem.generalItems, expandedIndices: $generalExpandedIndices).tag(Tab.generalDetectors.rawValue)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationTitle(viewItem.blockchain.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("button.close".localized) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

extension CoinAnalyticsIssuesView {
    struct DetectorsView: View {
        let items: [CoinAnalyticsViewModel.IssueViewItem]
        @Binding var expandedIndices: Set<Int>

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        let expanded = expandedIndices.contains(index)

                        VStack(alignment: .leading, spacing: 0) {
                            HorizontalDivider()

                            if item.issues.isEmpty {
                                itemContent(item: item, expanded: expanded)
                            } else {
                                itemContent(item: item, expanded: expanded)
                                    .onTapGesture {
                                        withAnimation {
                                            if expandedIndices.contains(index) {
                                                expandedIndices.remove(index)
                                            } else {
                                                expandedIndices.insert(index)
                                            }
                                        }
                                    }
                            }

                            if expanded {
                                ForEach(item.issues.indices, id: \.self) { index in
                                    let issue = item.issues[index].trimmingCharacters(in: .whitespacesAndNewlines)

                                    Text(issue)
                                        .textSubhead2()
                                        .multilineTextAlignment(.leading)
                                        .padding(.vertical, .margin12)
                                        .padding(.horizontal, .margin32)

                                    if index != item.issues.indices.count - 1 {
                                        HorizontalDivider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, .margin16)
            }
        }

        @ViewBuilder private func itemContent(item: CoinAnalyticsViewModel.IssueViewItem, expanded: Bool) -> some View {
            HStack(spacing: .margin8) {
                HStack(spacing: .margin16) {
                    switch item.level {
                    case .highRisk: Image("circle_warning_24").themeIcon(color: .themeLucian)
                    case .mediumRisk: Image("circle_warning_24").themeIcon(color: .themeJacob)
                    case .attentionRequired: Image("circle_warning_24").themeIcon(color: .themeRemus)
                    case .informational: Image("circle_warning_24").themeIcon(color: .themeLaguna)
                    case .regular: Image("circle_check_24").themeIcon(color: .themeLeah)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .textBody()
                            .multilineTextAlignment(.leading)

                        if let description = item.description {
                            Text(description)
                                .textSubhead2()
                                .multilineTextAlignment(.leading)
                        }
                    }
                }

                Spacer()

                if !item.issues.isEmpty {
                    HStack(spacing: .margin8) {
                        Text("coin_analytics.analysis.issues".localized(String(item.issues.count))).textSubhead1()
                        Image(expanded ? "arrow_big_up_20" : "arrow_big_down_20")
                    }
                }
            }
            .padding(.vertical, .margin12)
            .padding(.horizontal, .margin16)
            .background(Color.themeLawrence)
        }
    }
}

extension CoinAnalyticsIssuesView {
    enum Tab: Int, CaseIterable {
        case tokenDetectors
        case generalDetectors

        var title: String {
            switch self {
            case .tokenDetectors: return "coin_analytics.analysis.token_detectors".localized
            case .generalDetectors: return "coin_analytics.analysis.general_detectors".localized
            }
        }
    }
}
