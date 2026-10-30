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
                                    Cell(
                                        middle: { ThemeText("selector.any".localized, style: .headline2, colorStyle: .secondary) },
                                        right: {
                                            if viewModel.categories == .any {
                                                Image.checkIcon
                                            }
                                        },
                                        action: {
                                            viewModel.categories = .any
                                        }
                                    )

                                    ForEach(categories) { category in
                                        Cell(
                                            middle: { ThemeText(category.name, style: .headline2) },
                                            right: {
                                                if let id = category.id, viewModel.categories.include(id: id) {
                                                    Image.checkIcon
                                                }
                                            },
                                            action: {
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
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 0, leading: .margin16, bottom: .margin24, trailing: .margin16))
                    }
                } bottomContent: {
                    ThemeButton(text: buttonTitle()) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("market.advanced_search.categories".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
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
