import GRDB
import HsToolKit

final class OpenCryptoPayModule {
    let manager: OpenCryptoPayManager
    let paymentManager: OpenCryptoPayPaymentManager
    let proofWorkerProvider: OpenCryptoPayProofWorkerProvider

    init(dbPool: DatabasePool, networkManager: NetworkManager, walletManager: WalletManager, accountManager: AccountManager, logger: Logger?) {
        let provider = OpenCryptoPayProvider(networkManager: networkManager)
        manager = OpenCryptoPayManager(
            provider: provider,
            walletManager: walletManager,
            accountManager: accountManager,
            broadcasterFactory: OpenCryptoPayBroadcasterFactory.unstoppable
        )

        let storage = OpenCryptoPayPaymentStorage(dbPool: dbPool)
        paymentManager = OpenCryptoPayPaymentManager(storage: storage, accountManager: accountManager, logger: logger)
        proofWorkerProvider = OpenCryptoPayProofWorkerProvider(manager: paymentManager, submitter: OpenCryptoPaySubmitter(provider: provider))
    }
}
