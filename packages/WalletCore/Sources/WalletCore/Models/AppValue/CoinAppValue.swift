import MarketKit

// Currently uninvoked in construction; preserved to mirror the original .coin(coin:decimals:) enum case.
public struct CoinAppValue: IAppValue {
    public let coin: Coin?
    public let decimals: Int?

    public init(coin: Coin, decimals: Int) {
        self.coin = coin
        self.decimals = decimals
    }

    public var name: String { coin?.name ?? "" }
    public var code: String { coin?.code ?? "" }

    public func isSameKind(as other: any IAppValue) -> Bool {
        (other as? CoinAppValue).map { $0.coin == coin && $0.decimals == decimals } ?? false
    }
}
