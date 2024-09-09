import BigInt
import Foundation
import MarketKit
import TonKit
import TonSwift

class TonEventConverter {
    private let address: TonSwift.Address
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: CoinManager

    init(address: TonSwift.Address, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.address = address
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
    }

    private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimals, significand: significand)
    }

    private func tonValue(value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        let amount = convertAmount(amount: value, decimals: baseToken.decimals, sign: sign)
        return .coinValue(token: baseToken, value: amount)
    }

    private func jettonValue(jetton: Jetton, value: BigUInt, sign: FloatingPointSign) -> TransactionValue {
        let query = TokenQuery(blockchainType: .ton, tokenType: .jetton(address: jetton.address.toString(bounceable: true)))

        if let token = try? coinManager.token(query: query) {
            let value = convertAmount(amount: value, decimals: token.decimals, sign: sign)
            return .coinValue(token: token, value: value)
        } else {
            let value = convertAmount(amount: value, decimals: jetton.decimals, sign: sign)
            return .jettonValue(jetton: jetton, value: value)
        }
    }

    private func format(address: AccountAddress) -> String {
        address.address.toString(bounceable: !address.isWallet)
    }

    private func actionType(type: Action.`Type`) -> TonTransactionRecord.Action.`Type` {
        switch type {
        case let .tonTransfer(action):
            if action.sender.address == address {
                return .send(value: tonValue(value: action.amount, sign: .minus), to: format(address: action.recipient), sentToSelf: action.recipient.address == address, comment: action.comment)
            } else if action.recipient.address == address {
                return .receive(value: tonValue(value: action.amount, sign: .plus), from: format(address: action.sender), comment: action.comment)
            } else {
                return .unsupported(type: "Ton Transfer")
            }
        case let .jettonTransfer(action):
            if action.sender?.address == address, let recipient = action.recipient {
                return .send(value: jettonValue(jetton: action.jetton, value: action.amount, sign: .minus), to: format(address: recipient), sentToSelf: action.recipient?.address == address, comment: action.comment)
            } else if action.recipient?.address == address, let sender = action.sender {
                return .receive(value: jettonValue(jetton: action.jetton, value: action.amount, sign: .plus), from: format(address: sender), comment: action.comment)
            } else {
                return .unsupported(type: "Jetton Transfer")
            }
        case let .jettonBurn(action):
            return .unsupported(type: "Jetton Burn")
        case let .jettonMint(action):
            return .unsupported(type: "Jetton Mint")
        case let .contractDeploy(action):
            return .contractDeploy(interfaces: action.interfaces)
        case let .jettonSwap(action):
            return .unsupported(type: "Jetton Swap")
        case let .smartContract(action):
            return .unsupported(type: "Smart Contract")
        case let .unknown(rawType):
            return .unsupported(type: rawType)
        }
    }
}

extension TonEventConverter {
    func transactionRecord(event: Event) -> TonTransactionRecord {
        let actions = event.actions.map { action in
            let status: TransactionStatus

            switch action.status {
            case .ok: status = .completed
            default: status = .failed
            }

            return TonTransactionRecord.Action(
                type: actionType(type: action.type),
                status: status
            )
        }

        return TonTransactionRecord(source: source, event: event, baseToken: baseToken, actions: actions)
    }
}
