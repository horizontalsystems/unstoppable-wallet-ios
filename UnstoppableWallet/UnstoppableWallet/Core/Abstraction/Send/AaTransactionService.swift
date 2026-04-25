import BigInt
import Combine
import EvmKit
import Foundation
import HsToolKit
import MarketKit

class AaTransactionService {
    private let blockchainType: BlockchainType
    private let entryPoint: EvmKit.Address
    private let chainId: BigUInt
    private let sender: EvmKit.Address
    private let evmKit: EvmKit.Kit
    private let pimlicoProvider: PimlicoProvider

    private let updateSubject = PassthroughSubject<Void, Never>()

    private(set) var recommendedGasPrice: PimlicoProvider.GasPrices.Tier?
    private(set) var nextNonce: BigUInt?

    init?(blockchainType: BlockchainType, account: Account, initialTransactionSettings _: InitialTransactionSettings?) {
        let core = Core.shared
        guard case .passkeyOwned = account.type,
              let chain = try? core.evmBlockchainManager.chain(blockchainType: blockchainType),
              let evmKitWrapper = try? core.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper(account: account, blockchainType: blockchainType),
              let entryPoint = ChainAddresses.aa(for: blockchainType)?.entryPoint,
              let apiKey = AppConfig.pimlicoApiKey,
              let pimlicoProvider = try? PimlicoProvider(networkManager: core.networkManager, blockchainType: blockchainType, entryPoint: entryPoint, apiKey: apiKey),
              let sender = account.type.evmAddress(chain: chain)
        else {
            return nil
        }

        self.blockchainType = blockchainType
        self.entryPoint = entryPoint
        chainId = BigUInt(chain.id)
        self.sender = sender
        evmKit = evmKitWrapper.evmKit
        self.pimlicoProvider = pimlicoProvider
    }
}

extension AaTransactionService: ITransactionService {
    var transactionSettings: TransactionSettings? {
        guard let recommendedGasPrice, let nextNonce else { return nil }
        return .aa(
            maxFeePerGas: recommendedGasPrice.maxFeePerGas,
            maxPriorityFeePerGas: recommendedGasPrice.maxPriorityFeePerGas,
            nonce: nextNonce
        )
    }

    var modified: Bool { false }

    var cautions: [CautionNew] { [] }

    var updatePublisher: AnyPublisher<Void, Never> { updateSubject.eraseToAnyPublisher() }

    func sync() async throws {
        async let gasPrices = pimlicoProvider.getUserOperationGasPrice()
        async let nonceData = evmKit.fetchCall(
            contractAddress: entryPoint,
            data: EntryPointV06.encodeGetNonce(sender: sender, key: 0),
            defaultBlockParameter: .latest
        )

        let (g, n) = try await (gasPrices, nonceData)
        recommendedGasPrice = g.standard
        nextNonce = try EntryPointV06.decodeGetNonce(n)

        updateSubject.send()
    }
}
