import SwiftUI

struct ScamFilterModule {
    static func view() -> some View {
        let viewModel = ScamFilterViewModel(scamFilterManager: App.shared.scamFilterManager)
        return ScamFilterView(viewModel: viewModel)
    }
}
