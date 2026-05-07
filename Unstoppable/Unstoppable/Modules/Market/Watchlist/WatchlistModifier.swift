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
                        Image("heart_24").renderingMode(.template)
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
                Image("heart_fill_20")
                    .renderingMode(.template)
                    .foregroundColor(.themeJacob)
                    .frame(width: .iconSize20, height: .iconSize20)
            }
            .tappablePadding(.margin12, onTap: {
                viewModel.remove(coinUid: coinUid)
            })
        } else {
            Button {
                viewModel.add(coinUid: coinUid)
            } label: {
                Image("heart_20")
                    .renderingMode(.template)
                    .foregroundColor(.themeGray)
                    .frame(width: .iconSize20, height: .iconSize20)
            }
            .tappablePadding(.margin12, onTap: {
                viewModel.add(coinUid: coinUid)
            })
        }
    }
}
