import EvmKit
import Foundation
import MarketKit
import SwiftUI

struct MultiSwapRevokeView: View {
    @StateObject private var viewModel: MultiSwapRevokeViewModel
    @Binding private var isPresented: Bool
    private let onSuccess: () -> Void

    @State private var unlockPresented = false
    @Environment(\.dismiss) private var dismiss

    init(tokenIn: Token, spenderAddress: EvmKit.Address, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: MultiSwapRevokeViewModel(token: tokenIn, spenderAddress: spenderAddress))
        _isPresented = isPresented
        self.onSuccess = onSuccess
    }

    var body: some View {
        if let transactionData = viewModel.transactionData {
            SendConfirmationNewView(sendData: .evm(blockchainType: viewModel.token.blockchainType, transactionData: transactionData)) {
                onSuccess()
                isPresented = false
            }
        }
    }
}
