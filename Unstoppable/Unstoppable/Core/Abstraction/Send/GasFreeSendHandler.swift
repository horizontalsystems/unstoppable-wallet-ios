import BigInt
import Foundation
import MarketKit
import TronKit

class GasFreeSendHandler {
    let baseToken: Token
    private let account: Account
    private let token: TronKit.Address
    private let receiver: TronKit.Address
    private let value: BigUInt
    private let sender: GasFreeSender

    init(baseToken: Token, account: Account, token: TronKit.Address, receiver: TronKit.Address, value: BigUInt, sender: GasFreeSender) {
        self.baseToken = baseToken
        self.account = account
        self.token = token
        self.receiver = receiver
        self.value = value
        self.sender = sender
    }
}

extension GasFreeSendHandler: ISendHandler {
    var expirationDuration: Int? { 30 }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let prepared = try await sender.prepare(
            account: account,
            token: token,
            value: value,
            receiver: receiver,
            baseToken: baseToken
        )
        return GasFreeSendData(prepared: prepared, token: baseToken)
    }

    func send(data: ISendData) async throws {
        guard let data = data as? GasFreeSendData else { throw SendError.invalidData }
        _ = try await sender.submit(account: account, prepared: data.prepared)
    }
}

extension GasFreeSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension GasFreeSendHandler {
    static func instance(token: Token, receiver: TronKit.Address, value: BigUInt, account: Account) -> GasFreeSendHandler? {
        let core = Core.shared

        guard token.blockchainType == .tron,
              case let .eip20(tokenHex) = token.type,
              let tokenAddress = try? TronKit.Address(address: tokenHex),
              case .passkeyOwned = account.type,
              let apiKey = AppConfig.gasFreeApiKey,
              let apiSecret = AppConfig.gasFreeApiSecret,
              let provider = try? GasFreeProvider(networkManager: core.networkManager, apiKey: apiKey, apiSecret: apiSecret)
        else {
            return nil
        }

        let sender = GasFreeSender(
            provider: provider,
            smartAccountManager: core.smartAccountManager,
            passkeyManager: PasskeyManager()
        )

        return GasFreeSendHandler(
            baseToken: token,
            account: account,
            token: tokenAddress,
            receiver: receiver,
            value: value,
            sender: sender
        )
    }
}
