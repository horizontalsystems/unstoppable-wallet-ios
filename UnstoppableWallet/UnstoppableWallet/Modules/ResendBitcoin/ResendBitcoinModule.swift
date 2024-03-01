import UIKit

enum ResendBitcoinModule {
    private static func replacementInfo(adapter: BitcoinBaseAdapter, transactionHash: String, type: ResendTransactionType) -> (Int, Range<Int>)? {
        switch type {
            case .speedUp:
                return adapter.speedUpTransactionInfo(transactionHash: transactionHash)
            case .cancel:
                return adapter.cancelTransactionInfo(transactionHash: transactionHash)
        }
    }

    static func resendViewController(adapter: ITransactionsAdapter, type: ResendTransactionType, transactionRecord: BitcoinTransactionRecord) throws -> UIViewController {
        guard let adapter = adapter as? BitcoinBaseAdapter,
              let (originalSize, feeRange) = replacementInfo(adapter: adapter, transactionHash: transactionRecord.transactionHash, type: type),
              let feeRateProvider = App.shared.feeRateProviderFactory.provider(blockchainType: adapter.token.blockchainType)
        else {
            throw CreateModuleError.wrongTransaction
        }

        let token = adapter.token
        let currency = App.shared.currencyManager.baseCurrency
        let price = App.shared.marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currency.code)

        let service = ResendBitcoinService(
            transactionRecord: transactionRecord,
            feeRange: feeRange,
            feeRateProvider: feeRateProvider,
            originalSize: originalSize,
            type: type,
            adapter: adapter,
            token: token,
            currency: currency,
            price: price?.value,
            logger: App.shared.logger
        )
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: token.blockchainType)
        let viewModel = ResendBitcoinViewModel(service: service, contactLabelService: contactLabelService)

        return ResendBitcoinViewController(viewModel: viewModel)
    }
}

extension ResendBitcoinModule {
    enum CreateModuleError: LocalizedError {
        case wrongTransaction
        case cantCreateFeeRateProvider
        case cantCreateFeeSettingsModule
        case alreadyInBlock

        var errorDescription: String? {
            switch self {
                case .wrongTransaction, .cantCreateFeeRateProvider, .cantCreateFeeSettingsModule: return "alert.unknown_error".localized
                case .alreadyInBlock: return "tx_info.transaction.already_in_block".localized
            }
        }
    }
}
