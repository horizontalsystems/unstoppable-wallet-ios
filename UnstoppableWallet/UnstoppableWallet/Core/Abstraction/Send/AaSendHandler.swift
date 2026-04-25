import BigInt
import EvmKit
import Foundation
import MarketKit

class AaSendHandler {
    let baseToken: Token
    private let account: Account
    private let transactionData: TransactionData
    private let tokenAddress: EvmKit.Address
    private let aaSender: AaSender

    init(baseToken: Token, account: Account, transactionData: TransactionData, tokenAddress: EvmKit.Address, aaSender: AaSender) {
        self.baseToken = baseToken
        self.account = account
        self.transactionData = transactionData
        self.tokenAddress = tokenAddress
        self.aaSender = aaSender
    }
}

extension AaSendHandler: ISendHandler {
    var expirationDuration: Int? { 30 }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        var maxFeePerGas: BigUInt?
        var maxPriorityFeePerGas: BigUInt?
        var nonce: BigUInt?
        if case let .aa(mfpg, mpfpg, n) = transactionSettings {
            maxFeePerGas = mfpg
            maxPriorityFeePerGas = mpfpg
            nonce = n
        }

        let gasPriceTier: PimlicoProvider.GasPrices.Tier? = maxFeePerGas.map {
            PimlicoProvider.GasPrices.Tier(maxFeePerGas: $0, maxPriorityFeePerGas: maxPriorityFeePerGas ?? 0)
        }

        let prepared = try await aaSender.prepare(
            account: account,
            transactionData: transactionData,
            tokenAddress: tokenAddress,
            baseToken: baseToken,
            gasPrices: gasPriceTier,
            nonce: nonce
        )

        return AaSendData(prepared: prepared, baseToken: baseToken)
    }

    func send(data: ISendData) async throws {
        guard let aaData = data as? AaSendData else { throw SendError.invalidData }
        _ = try await aaSender.submit(account: account, prepared: aaData.prepared)
    }
}

extension AaSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension AaSendHandler {
    static func instance(blockchainType: BlockchainType, transactionData: TransactionData, token: Token, account: Account) -> AaSendHandler? {
        let core = Core.shared

        guard let chain = try? core.evmBlockchainManager.chain(blockchainType: blockchainType),
              let entryPoint = ChainAddresses.aa(for: blockchainType)?.entryPoint,
              let evmKit = (try? core.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper(account: account, blockchainType: blockchainType))?.evmKit,
              let apiKey = AppConfig.pimlicoApiKey,
              case let .eip20(tokenAddressHex) = token.type,
              let tokenAddress = try? EvmKit.Address(hex: tokenAddressHex),
              let httpSyncSource = core.evmSyncSourceManager.httpSyncSource(blockchainType: blockchainType)
        else {
            return nil
        }

        guard let pimlicoProvider = try? PimlicoProvider(networkManager: core.networkManager, blockchainType: blockchainType, entryPoint: entryPoint, apiKey: apiKey),
              let codeProvider = try? EvmCodeProvider(networkManager: core.networkManager, blockchainType: blockchainType, rpcSource: httpSyncSource.rpcSource)
        else {
            return nil
        }

        let aaSender = AaSender(
            blockchainType: blockchainType,
            entryPoint: entryPoint,
            chainId: BigUInt(chain.id),
            evmKit: evmKit,
            pimlicoProvider: pimlicoProvider,
            codeProvider: codeProvider,
            passkeyManager: core.smartAccountPasskeyManager,
            smartAccountManager: core.smartAccountManager
        )

        return AaSendHandler(baseToken: token, account: account, transactionData: transactionData, tokenAddress: tokenAddress, aaSender: aaSender)
    }
}
