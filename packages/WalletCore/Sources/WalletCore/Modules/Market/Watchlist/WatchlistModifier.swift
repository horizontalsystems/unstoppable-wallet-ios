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
                        Image("heart_broke_24").renderingMode(.template)
                    }
                    .tint(.themeLucian)
                } else {
                    Button {
                        viewModel.add(coinUid: coinUid)
                    } label: {
                        Image("heart").renderingMode(.template)
                    }
                    .tint(.themeJacob)
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
                ThemeImage("heart_filled", size: .iconSize20, colorStyle: .yellow)
            }
            .tappablePadding(.margin12, onTap: {
                viewModel.remove(coinUid: coinUid)
            })
        } else {
            Button {
                viewModel.add(coinUid: coinUid)
            } label: {
                ThemeImage("heart", size: .iconSize20, colorStyle: .secondary)
            }
            .tappablePadding(.margin12, onTap: {
                viewModel.add(coinUid: coinUid)
            })
        }
    }
}
