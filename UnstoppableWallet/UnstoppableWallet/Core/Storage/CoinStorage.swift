class CoinStorage {
    private let storage: ICoinRecordStorage

    init(storage: ICoinRecordStorage) {
        self.storage = storage
    }

    private func coin(record: CoinRecord) -> Coin? {
        guard let tokenType = TokenType(rawValue: record.tokenType) else {
            return nil
        }

        switch tokenType {
        case .erc20:
            guard let address = record.erc20Address else {
                return nil
            }

            return coin(record: record, coinType: CoinType(erc20Address: address))
        }
    }

    private func coinRecord(coin: Coin, tokenType: TokenType) -> CoinRecord {
        CoinRecord(
                id: coin.id,
                title: coin.title,
                code: coin.code,
                decimal: coin.decimal,
                tokenType: tokenType.rawValue
        )
    }

    private func coin(record: CoinRecord, coinType: CoinType) -> Coin {
        Coin(
                id: record.id,
                title: record.title,
                code: record.code,
                decimal: record.decimal,
                type: coinType
        )
    }

}

extension CoinStorage: ICoinStorage {

    var coins: [Coin] {
        storage.coinRecords.compactMap { coin(record: $0) }
    }

    func save(coin: Coin) -> Bool {
        switch coin.type {
        case .erc20(let address, _, _, _):
            let record = coinRecord(coin: coin, tokenType: .erc20)
            record.erc20Address = address
            storage.save(coinRecord: record)
            return true
        default: ()
        }

        return false
    }

}

extension CoinStorage {

    enum TokenType: String {
        case erc20
    }

}
