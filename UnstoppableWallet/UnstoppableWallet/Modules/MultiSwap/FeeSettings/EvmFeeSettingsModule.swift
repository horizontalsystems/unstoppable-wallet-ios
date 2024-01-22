import SwiftUI

struct EvmFeeSettingsModule {
    static func view() -> some View {
        Eip1559FeeSettingsView(viewModel: Eip1559FeeSettingsViewModel())
    }
}
