import EvmKit
import Foundation
import RxCocoa
import RxRelay

class WCSignEthereumTransactionRequestViewModel {
    private let requestId: Int
    private let payload: WCEthereumTransactionPayload
    private let evmKitWrapper: EvmKitWrapper
    private let wcService: IWalletConnectSignService

    private let errorRelay = PublishRelay<Error>()
    private let dismissRelay = PublishRelay<Void>()

    init(requestId: Int, payload: WCEthereumTransactionPayload, evmKitWrapper: EvmKitWrapper, wcService: IWalletConnectSignService) {
        self.requestId = requestId
        self.payload = payload
        self.evmKitWrapper = evmKitWrapper
        self.wcService = wcService
    }
}

extension WCSignEthereumTransactionRequestViewModel {
    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    var dismissSignal: Signal<Void> {
        dismissRelay.asSignal()
    }

    var transactionData: TransactionData {
        TransactionData(
            to: payload.transaction.to,
            value: payload.transaction.value,
            input: payload.transaction.data
        )
    }

    var gasPrice: GasPrice? {
        if let maxFeePerGas = payload.transaction.maxFeePerGas,
           let maxPriorityFeePerGas = payload.transaction.maxPriorityFeePerGas
        {
            return GasPrice.eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
        }

        return payload.transaction.gasPrice.flatMap { GasPrice.legacy(gasPrice: $0) }
    }

    func sign() {
        do {
            let wcTransaction = payload.transaction

            let gasPrice: GasPrice

            if let maxFeePerGas = wcTransaction.maxFeePerGas, let maxPriorityFeePerGas = wcTransaction.maxPriorityFeePerGas {
                gasPrice = .eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
            } else if let wcGasPrice = wcTransaction.gasPrice {
                gasPrice = .legacy(gasPrice: wcGasPrice)
            } else {
                throw TransactionError.invalidGasPrice
            }

            guard let gasLimit = wcTransaction.gasLimit else {
                throw TransactionError.invalidGasLimit
            }

            guard let nonce = wcTransaction.nonce else {
                throw TransactionError.invalidNonce
            }

            guard let signer = evmKitWrapper.signer else {
                throw TransactionError.noSigner
            }

            let signedTransaction = try signer.signedTransaction(
                address: wcTransaction.to,
                value: wcTransaction.value,
                transactionInput: wcTransaction.data,
                gasPrice: gasPrice,
                gasLimit: gasLimit,
                nonce: nonce
            )

            wcService.approveRequest(id: requestId, result: signedTransaction)
            dismissRelay.accept(())
        } catch {
            errorRelay.accept(error)
        }
    }

    func reject() {
        wcService.rejectRequest(id: requestId)
    }
}

extension WCSignEthereumTransactionRequestViewModel {
    enum TransactionError: Error {
        case invalidGasPrice
        case invalidGasLimit
        case invalidNonce
        case noSigner
    }
}
