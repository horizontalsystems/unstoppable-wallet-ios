import BigInt
import BitcoinCore
import Foundation
import MarketKit

class BitcoinPreSendHandler {
    private let token: Token
    private let adapter: BitcoinBaseAdapter

    init(token: Token, adapter: BitcoinBaseAdapter) {
        self.token = token
        self.adapter = adapter
    }
}

extension BitcoinPreSendHandler: IPreSendHandler {
    func sendData(amount: Decimal, address: String, memo: String?) -> SendData? {
        let params = SendParameters(
            address: address,
            value: adapter.convertToSatoshi(value: amount),
            memo: memo
        )

        return .bitcoin(token: token, params: params)
    }
}
