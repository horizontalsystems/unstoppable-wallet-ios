import BitcoinCore
import SwiftUI

enum ResendBitcoinModule {
    static func present(adapter: BitcoinBaseAdapter, type: ResendTransactionType, transactionRecord: BitcoinOutgoingTransactionRecord) throws {
        let request = BitcoinResendRequest(token: adapter.token, transaction: transactionRecord, type: type)
        let viewModel = SendViewModel(sendData: .bitcoinResend(request))
        guard viewModel.handler != nil, viewModel.transactionService is BitcoinResendTransactionService else {
            throw CreateModuleError.unableToReplace
        }
        Coordinator.shared.present { isPresented in
            ThemeNavigationStack {
                BitcoinResendView(viewModel: viewModel, type: type) {
                    isPresented.wrappedValue = false
                }
            }
        }
    }
}

extension ResendBitcoinModule {
    enum CreateModuleError: LocalizedError {
        case unableToReplace

        var errorDescription: String? {
            "alert.unable_to_replace".localized
        }
    }
}

extension ReplacementTransactionBuildError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .feeTooLow: return "alert.fee_too_low".localized
        case .rbfNotEnabled: return "alert.rbf_not_Enabled".localized
        case .invalidTransaction, .noPreviousOutput, .unableToReplace: return "alert.unable_to_replace".localized
        case .alreadyReplaced: return "alert.already_replaced".localized
        }
    }
}
