import BigInt
import Foundation
import MarketKit
import TronKit

class TronSendHandler {
    let baseToken: Token
    private let token: Token
    private let contract: Contract
    private let tronKitWrapper: TronKitWrapper
    private let decorator = EvmDecorator()

    init(baseToken: Token, token: Token, contract: Contract, tronKitWrapper: TronKitWrapper) {
        self.baseToken = baseToken
        self.token = token
        self.contract = contract
        self.tronKitWrapper = tronKitWrapper
    }

    private func calculateTotalFees(fees: [Fee]) -> Int {
        var totalFees = 0
        for fee in fees {
            switch fee {
            case let .bandwidth(points, price):
                totalFees += points * price
            case let .energy(required, price):
                totalFees += required * price
            case let .accountActivation(amount):
                totalFees += amount
            }
        }

        return totalFees
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
            let _fees = try await tronKit.estimateFee(contract: contract)
            let _totalFees = calculateTotalFees(fees: _fees)

            var totalAmount = 0
            if let transfer = contract as? TransferContract {
                var sentAmount = transfer.amount
                if trxBalance == transfer.amount {
                    // If the maximum amount is being sent, then we subtract fees from sent amount
                    sentAmount = sentAmount - _totalFees

                    guard sentAmount > 0 else {
                        throw TransactionError.zeroAmount
                    }

                    contract = tronKit.transferContract(toAddress: transfer.toAddress, value: sentAmount)
                }
                totalAmount += sentAmount
            }

            totalAmount += _totalFees
            fees = _fees
            totalFees = _totalFees

            if trxBalance < totalAmount {
                throw TransactionError.insufficientBalance(balance: trxBalance)
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
        guard let data = data as? TronSendData else {
            throw SendError.invalidData
        }

        guard let contract = data.contract else {
            throw SendError.noContract
        }

        guard let totalFees = data.totalFees else {
            throw SendError.noFees
        }

        _ = try await tronKitWrapper.send(
            contract: contract,
            feeLimit: totalFees
        )
    }
}

extension TronSendHandler {
    enum SendError: Error {
        case invalidData
        case noFees
        case noContract
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: BigUInt)
        case zeroAmount
    }
}

extension TronSendHandler {
    static func instance(token: Token, contract: Contract) -> TronSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: .tron, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: token) as? ISendTronAdapter else {
            return nil
        }

        return TronSendHandler(
            baseToken: baseToken,
            token: token,
            contract: contract,
            tronKitWrapper: adapter.tronKitWrapper
        )
    }
}
