import MarketKit
import SwiftUI

struct MarketAdvancedSearchCategoriesView: View {
    @ObservedObject var viewModel: MarketAdvancedSearchViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                BottomGradientWrapper {
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
                                            guard let id = category.id else {
                                                return
                                            }

                                            switch viewModel.categories {
                                            case .any:
                                                viewModel.categories = .list([id])
                                            case var .list(array):
                                                if let index = array.firstIndex(of: id) {
                                                    array.remove(at: index)
                                                } else {
                                                    array.append(id)
                                                }
                                                viewModel.categories = array.isEmpty ? .any : .list(array)
                                            }
                                        } content: {
                                            Text(category.name).themeBody()

                                            if let id = category.id, viewModel.categories.include(id: id) {
                                                Image("check_1_20").themeIcon(color: .themeJacob)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
                    }
                } bottomContent: {
                    Button(buttonTitle()) {
                        isPresented = false
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }
            }
            .navigationTitle("market.advanced_search.categories".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
        }
    }

    func buttonTitle() -> String {
        switch viewModel.categories {
        case .any: return "button.done".localized
        case let .list(categories): return ["button.select".localized, categories.count.description].joined(separator: " ")
        }
    }
}
