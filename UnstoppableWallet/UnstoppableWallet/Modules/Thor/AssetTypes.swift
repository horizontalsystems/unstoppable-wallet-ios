
import BigInt
import Foundation

/*
 Type definitions as per
 https://github.com/xchainjs/xchainjs-lib/blob/master/packages/xchain-util/src/types/index.ts
 */

public extension Thorchain {
    /// Define an asset which is typically referred to as CHAIN.SYMBOL (e.g. BTC.BTC or THOR.RUNE)
    /// See https://docs.thorchain.org/developers/transaction-memos#asset-notation
    struct Asset: Equatable {
        public let chain: String
        public let symbol: String
        public let ticker: String

        /// Create a cryptocurrency Asset supported by Thorchain. Where possible use one of the provided static defined assets.
        /// - Parameters:
        ///   - chain: Cryptocurrency chain code, CAPS. e.g. THOR, BTC, ETH.
        ///   - symbol: Symbol of asset. e.g. RUNE, BTC, ETH. For ERC20 tokens, also append -{contract address}, e.g. "USDT-0xdac17f958d2ee523a2206206994597c13d831ec7"
        ///   - ticker: Typically the symbol (without the smart-contract address). e.g. BTC, ETH, USDT, RUNE.
        public init(chain: String, symbol: String, ticker: String) {
            self.chain = chain
            self.symbol = symbol
            self.ticker = ticker
        }

        /* Convenience initialisers for commonly supported chains */
        public static let RuneNative = Asset(chain: "THOR", symbol: "RUNE", ticker: "RUNE")
        public static let RuneB1A = Asset(chain: "BNB", symbol: "RUNE-B1A", ticker: "RUNE") // mainnet
        public static let Rune67C = Asset(chain: "BNB", symbol: "RUNE-67C", ticker: "RUNE") // testnet asset on binance ganges
        public static let RuneERC20 = Asset(chain: "ETH", symbol: "RUNE-0x3155ba85d5f96b2d030a4966af206230e46849cb", ticker: "RUNE")
        public static let RuneERC20Testnet = Asset(chain: "ETH", symbol: "RUNE-0xd601c6A3a36721320573885A8d8420746dA3d7A0", ticker: "RUNE")
        public static let BTC = Asset(chain: "BTC", symbol: "BTC", ticker: "BTC")
        public static let ETH = Asset(chain: "ETH", symbol: "ETH", ticker: "ETH")
        public static let USDT = Asset(chain: "ETH", symbol: "USDT-0xdac17f958d2ee523a2206206994597c13d831ec7", ticker: "USDT")
        public static let USDTTestnet = Asset(chain: "ETH", symbol: "USDT-0x62e273709Da575835C7f6aEf4A31140Ca5b1D190", ticker: "USDT")
        public static let BNB = Asset(chain: "BNB", symbol: "BNB", ticker: "BNB")
        public static let LTC = Asset(chain: "LTC", symbol: "LTC", ticker: "LTC")
        public static let BCH = Asset(chain: "BCH", symbol: "BCH", ticker: "BCH")
        public static let DOGE = Asset(chain: "DOGE", symbol: "DOGE", ticker: "DOGE")

        /// Create memo string from this Asset
        public var memoString: String {
            "\(chain).\(symbol)"
        }
    }
}

/// Holds a base amount, e.g. tor (1 RUNE = 100,000,000 tor).
/// This is 1e8 decimals as used internally in the Thorchain network.
public struct BaseAmount: ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
    public let amount: BigInt
    public let decimals: Int

    /// Computed property to convert base amount (e.g. 150,000,000 tor) to AssetAmount (e.g. 1.5 RUNE)
    public var assetAmount: AssetAmount {
        let zeros = BigInt(10).power(decimals)
        let (quotient, remainder) = amount.quotientAndRemainder(dividingBy: zeros)
        // BigInt and Decimal don't interact, so we need to go via String
        let quotientString: String = quotient.description // e.g. "2"
        let remainderString: String = remainder.description // e.g. "50000000"
        let zerosString: String = zeros.description // e.g. 100000000
        if let quotientDecimal = Decimal(string: quotientString),
           let remainderDecimal = Decimal(string: remainderString),
           let zerosDecimal = Decimal(string: zerosString)
        {
            // Use full support of Decimal digits if able
            let fraction: Decimal = quotientDecimal + remainderDecimal / zerosDecimal
            return AssetAmount(fraction, decimal: decimals)
        } else {
            // Use Doubles and truncate to 12 decimals
            let fraction = Double(quotient) + Double(remainder) / Double(zeros)
            return AssetAmount(Decimal(fraction), decimal: decimals)
        }
    }

    /// Create a BaseAmount. These types have no decimal place.
    /// - Parameters:
    ///   - amount: Amount of base unit
    ///   - decimal: Decimal places for this asset. Defaults to 8 for historical reasons.
    public init(_ amount: BigInt, decimal: Int = AssetAmount.defaultDecimal) {
        self.amount = amount
        decimals = decimal
    }

    /// Ability to represent a BaseAmount as an Integer, e.g. 1000
    public init(integerLiteral: Int) {
        amount = BigInt(integerLiteral)
        decimals = AssetAmount.defaultDecimal
    }

    /// Ability to represent BaseAmount as a String, e.g. "100000000000"
    public init(stringLiteral: String) {
        amount = BigInt(stringLiteral: stringLiteral)
        decimals = AssetAmount.defaultDecimal
    }
}

/// Holds a floating point asset amount, eg. 1.35 RUNE
public struct AssetAmount {
    public let amount: Decimal // Foundation type. Good for ~38 decimal digits
    public let decimals: Int

    /// Computed property to convert asset amount (e.g. 1.5 RUNE) to BaseAmount (e.g. 150,000,000 tor)
    public var baseAmount: BaseAmount {
        let power: Decimal = pow(10, decimals)
        var baseAmount: Decimal = (amount * power)
        var baseAmountRounded: Decimal = 0
        NSDecimalRound(&baseAmountRounded, &baseAmount, 0, .plain) // Remove decimal places so BigInt can ingest
        let baseAmountRoundedString: String = baseAmountRounded.description
        let bigIntFromString = BigInt(stringLiteral: baseAmountRoundedString)
        return BaseAmount(bigIntFromString)
    }

    /// Create an AssetAmount. These are a floating point description of a major asset, e.g. 1.4 RUNE (not the base amount)
    /// - Parameters:
    ///   - amount: Amount of asset
    ///   - decimal: Amount of decimals the base unit uses. Defaults to 8 for historical reasons.
    public init(_ amount: Decimal, decimal: Int = AssetAmount.defaultDecimal) {
        self.amount = amount
        decimals = decimal
    }

    public static let defaultDecimal = 8
}

extension AssetAmount: ExpressibleByFloatLiteral {
    /// Initialise asset amount from a float literal, e.g. 1.0.  Creates with decimals = 8 (default Thorchain internal implementation amount)
    /// - Parameter floatLiteral: Amount of Asset
    public init(floatLiteral: Double) {
        amount = Decimal(floatLiteral)
        decimals = Self.defaultDecimal
    }
}

extension AssetAmount: ExpressibleByIntegerLiteral {
    /// Initialise asset amount from an int literal, e.g. 2  Creates with decimals = 8 (default Thorchain internal implementation amount)
    /// - Parameter floatLiteral: Amount of Asset
    public init(integerLiteral: Int) {
        amount = Decimal(integerLiteral)
        decimals = Self.defaultDecimal
    }
}

public extension Decimal {
    /// Truncate to N decimals
    /// - Parameter numberOfDecimals: Number of decimals to truncate to.
    /// - Returns: Truncated Decimal number. e.g. 4.123 truncated to 2 returns 4.12
    func truncate(_ numberOfDecimals: Int) -> Decimal {
        var roundedValue: Decimal = 0
        var mutableSelf = self
        NSDecimalRound(&roundedValue, &mutableSelf, numberOfDecimals, .plain)
        return roundedValue
    }
}
