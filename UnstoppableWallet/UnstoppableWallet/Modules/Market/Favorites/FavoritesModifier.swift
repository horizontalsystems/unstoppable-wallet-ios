import SwiftUI

struct FavoritesModifier: ViewModifier {
    @ObservedObject var viewModel: FavoritesViewModel
    let coinUid: String

    func body(content: Content) -> some View {
        content
            .swipeActions {
                if viewModel.coinUids.contains(coinUid) {
                    Button {
                        viewModel.remove(coinUid: coinUid)
                    } label: {
                        Image("star_off_24").renderingMode(.template)
                    }
                    .tint(.themeLucian)
                } else {
                    Button {
                        viewModel.add(coinUid: coinUid)
                    } label: {
                        Image("star_24").renderingMode(.template)
                    }
                    .tint(.themeJacob)
                }
            }
    }
}

extension View {
    func favoriteSwipeActions(viewModel: FavoritesViewModel, coinUid: String) -> some View {
        modifier(FavoritesModifier(viewModel: viewModel, coinUid: coinUid))
    }
}
