import SwiftUI

struct SwapInfoView: View {
    @StateObject var viewModel: SwapInfoViewModel

    init(swap: Swap) {
        _viewModel = StateObject(wrappedValue: SwapInfoViewModel(swap: swap))
    }

    var body: some View {
        ThemeView {
            ScrollView {
                VStack(spacing: 16) {
                    viewModel.sections.sectionViews
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 32, trailing: 16))
            }
        }
        .navigationTitle("swap_info.title".localized)
    }
}
