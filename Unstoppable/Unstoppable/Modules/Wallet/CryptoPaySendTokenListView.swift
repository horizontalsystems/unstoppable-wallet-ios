import SwiftUI

struct CryptoPaySendTokenListView: View {
    let options: SendTokenListViewModel.SendOptions
    let prepare: (Wallet) async throws -> SendTokenListViewModel.SendOptions
    @Binding var isPresented: Bool

    var body: some View {
        SendTokenListView(options: options, isPresented: $isPresented) { wallet in
            HudHelper.instance.show(banner: .preparing)
            do {
                let prepared = try await prepare(wallet)
                HudHelper.instance.hide()
                return prepared
            } catch is CancellationError {
                HudHelper.instance.hide()
                throw CancellationError()
            } catch {
                HudHelper.instance.hide()
                HudHelper.instance.show(banner: .error(string: error.smartDescription))
                throw error
            }
        }
    }
}
