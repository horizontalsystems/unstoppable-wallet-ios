import BigInt
import Foundation
import MarketKit
import TronKit

class TronSendHandler: SendHandler {
    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .tron(token, contract) = sendData else { return nil }
        return instance(token: token, contract: contract)
    }

    let baseToken: Token
    private let token: Token
    private let contract: Contract
    private let tronKitWrapper: TronKitWrapper
    private let balanceAdapter: IBalanceAdapter?
    private let decorator = EvmDecorator()

    init(baseToken: Token, token: Token, contract: Contract, tronKitWrapper: TronKitWrapper, balanceAdapter: IBalanceAdapter?) {
        self.baseToken = baseToken
        self.token = token
        self.contract = contract
        self.tronKitWrapper = tronKitWrapper
        self.balanceAdapter = balanceAdapter
    }
}

extension TronSendHandler: ISendHandler {
    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        var totalFees: Int?
        var fees: [Fee]?
        var transactionError: Error?
        var contract = contract

        let tronKit = tronKitWrapper.tronKit
        let trxBalance = tronKit.trxBalance

        do {
            // Same intent as the TRX total check below, for the TRC20 leg (unchecked otherwise):
            // a token shortfall is answered locally, with the token named, instead of surfacing a
            // node revert after estimation.
            if let balanceAdapter, case .synced = balanceAdapter.balanceState,
               Self.isInsufficientTrc20Balance(
                   decoration: tronKit.decorate(contract: contract),
                   token: token,
                   availableBalance: balanceAdapter.balanceData.available
               )
            {
                throw TronSendHelper.TransactionError.insufficientTokenBalance(
                    balance: balanceAdapter.balanceData.available,
                    token: token
                )
            }

            let _fees = try await tronKit.estimateFee(contract: contract)
            let _totalFees = _fees.calculateTotalFees()

            var totalAmount = 0
            if let transfer = contract as? TransferContract {
                var sentAmount = transfer.amount
                if trxBalance == transfer.amount {
                    // If the maximum amount is being sent, then we subtract fees from sent amount
                    sentAmount = sentAmount - _totalFees

                    guard sentAmount > 0 else {
                        throw TronSendHelper.TransactionError.zeroAmount
                    }

                    contract = tronKit.transferContract(toAddress: transfer.toAddress, value: sentAmount)
                }
                totalAmount += sentAmount
            }

            totalAmount += _totalFees
            fees = _fees
            totalFees = _totalFees

            if trxBalance < totalAmount {
                throw TronSendHelper.TransactionError.insufficientBalance(balance: trxBalance)
            }
        } catch {
            transactionError = error
        }

        return TronSendData(
            token: token,
            baseToken: baseToken,
            decoration: tronKit.decorate(contract: contract),
            contract: contract,
            rateCoins: Array(Set([baseToken.coin, token.coin])),
            transactionError: transactionError,
            fees: fees,
            totalFees: totalFees
        )
    }

    func send(data: ISendData) async throws {
        _ = try await sendCapturingRef(data: data)
    }
}

extension TronSendHandler: ISendHandlerRefCapturing {
    // Same broadcast path as `send`. The Tron tx hash IS the created transaction's `txID`.
    func sendCapturingRef(data: ISendData) async throws -> String {
        guard let data = data as? TronSendData else {
            throw SendError.invalidData
        }

        guard let contract = data.contract else {
            throw SendError.noContract
        }

        guard let totalFees = data.totalFees else {
            throw SendError.noFees
        }

        let created = try await tronKitWrapper.send(
            contract: contract,
            feeLimit: totalFees
        )

        return created.txID.hs.hex
    }
}

extension TronSendHandler {
    enum SendError: Error {
        case invalidData
        case noFees
        case noContract
    }
}

extension TronSendHandler {
    static func instance(token: Token, contract: Contract) -> TronSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .tron, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ISendTronAdapter else {
            return nil
        }

        return TronSendHandler(
            baseToken: baseToken,
            token: token,
            contract: contract,
            tronKitWrapper: adapter.tronKitWrapper,
            balanceAdapter: adapter as? IBalanceAdapter
        )
    }

    static func isInsufficientTrc20Balance(decoration: TransactionDecoration?, token: Token, availableBalance: Decimal?) -> Bool {
        guard case let .eip20(address) = token.type,
              let tokenAddress = try? TronKit.Address(address: address),
              let transfer = decoration as? OutgoingEip20Decoration,
              transfer.contractAddress == tokenAddress,
              let availableBalance,
              let amount = Decimal(bigUInt: transfer.value, decimals: token.decimals)
        else {
            return false
        }

        return amount > availableBalance
    }
}
