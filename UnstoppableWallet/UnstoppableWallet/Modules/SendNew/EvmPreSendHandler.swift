import BigInt
import EvmKit
import Foundation
import MarketKit

class EvmPreSendHandler {
    private let token: Token
    private let adapter: ISendEthereumAdapter

    init(token: Token, adapter: ISendEthereumAdapter) {
        self.token = token
        self.adapter = adapter
    }
}

extension EvmPreSendHandler: IPreSendHandler {
    func sendData(amount: Decimal, address: String, memo _: String?) -> SendData? {
        guard let evmAmount = BigUInt(amount.hs.roundedString(decimal: token.decimals)) else {
            return nil
        }

        guard let evmAddress = try? EvmKit.Address(hex: address) else {
            return nil
        }

        let transactionData = adapter.transactionData(amount: evmAmount, address: evmAddress)

        return .evm(blockchainType: token.blockchainType, transactionData: transactionData)
    }
}
