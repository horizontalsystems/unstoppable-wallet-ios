import SwiftUI

struct WatchlistModifier: ViewModifier {
    @ObservedObject var viewModel: WatchlistViewModel
    let coinUid: String

    func body(content: Content) -> some View {
        content
            .swipeActions {
                if viewModel.coinUids.contains(coinUid) {
                    Button {
                        viewModel.remove(coinUid: coinUid)
                    } label: {
                        Label {
                            Text("button.remove_from_favorites".localized)
                        } icon: {
                            Image("heart_off").renderingMode(.template)
                        }
                        .labelStyle(.iconOnly)
                    }
                    .tint(.themeLucian)
                } else {
                    Button {
                        viewModel.add(coinUid: coinUid)
                    } label: {
                        Label {
                            Text("button.add_to_favorites".localized)
                        } icon: {
                            Image("heart").renderingMode(.template)
                        }
                        .labelStyle(.iconOnly)
                    }
                    .tint(.themeBrand)
                }
            }
    }
}

extension View {
    func watchlistSwipeActions(viewModel: WatchlistViewModel, coinUid: String) -> some View {
        modifier(WatchlistModifier(viewModel: viewModel, coinUid: coinUid))
    }
}

enum WatchlistView {
    @ViewBuilder static func watchButton(viewModel: WatchlistViewModel, coinUid: String) -> some View {
        if viewModel.coinUids.contains(coinUid) {
            Button {
                viewModel.remove(coinUid: coinUid)
            } label: {
                ThemeImage("heart_filled", size: .iconSize20, colorStyle: .brand)
            }
            .accessibilityLabel("button.remove_from_favorites".localized)
            .tappablePadding(.margin12, onTap: {
                viewModel.remove(coinUid: coinUid)
            })
        } else {
            Button {
                viewModel.add(coinUid: coinUid)
            } label: {
                ThemeImage("heart", size: .iconSize20, colorStyle: .secondary)
            }
            .accessibilityLabel("button.add_to_favorites".localized)
            .tappablePadding(.margin12, onTap: {
                viewModel.add(coinUid: coinUid)
            })
        }
    }
}
