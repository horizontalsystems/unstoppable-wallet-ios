import MarketKit
import SwiftUI

struct MarketAdvancedSearchCategoriesView: View {
    @ObservedObject var viewModel: MarketAdvancedSearchViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image("circle_portfolio_24").themeIcon(color: .themeJacob)
                Text("market.advanced_search.categories".localized).themeHeadline2()
                Button(action: { isPresented = false }) { Image("close_3_24").themeIcon() }
            }
            .padding(.horizontal, .margin32)
            .padding(.vertical, .margin24)

            BottomGradientWrapper(backgroundColor: .themeLawrence) {
                ScrollView {
                    VStack(spacing: .margin24) {
                        ListSection {
                            switch viewModel.allCategoriesState {
                            case .loading: EmptyView()
                            case .failed: EmptyView()
                            case let .loaded(categories):
                                ClickableRow {
                                    viewModel.categories = .any
                                } content: {
                                    Text("selector.any".localized).themeBody(color: .themeGray)

                                    if viewModel.categories == .any {
                                        Image("check_1_20").themeIcon(color: .themeJacob)
                                    }
                                }

                                ForEach(categories) { category in
                                    ClickableRow {
                                        switch viewModel.categories {
                                        case .any: viewModel.categories = .list([category.id])
                                        case var .list(array):
                                            if let index = array.firstIndex(of: category.id) {
                                                array.remove(at: index)
                                            } else {
                                                array.append(category.id)
                                            }
                                            viewModel.categories = array.isEmpty ? .any : .list(array)
                                        }
                                    } content: {
                                        Text(category.name).themeBody()

                                        if viewModel.categories.include(id: category.id) {
                                            Image("check_1_20").themeIcon(color: .themeJacob)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .themeListStyle(.bordered)
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
                }
            } bottomContent: {
                Button(buttonTitle()) {
                    isPresented = false
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }
        }
        .background(Color.themeLawrence)
    }

    func buttonTitle() -> String {
        switch viewModel.categories {
        case .any: return "button.done".localized
        case let .list(categories): return ["button.select".localized, categories.count.description].joined(separator: " ")
        }
    }
}

extension CoinCategory: Identifiable {}
