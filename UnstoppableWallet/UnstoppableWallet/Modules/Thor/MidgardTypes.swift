import Foundation
// MARK: API Object Mappings

/// Stores an IP address, e.g. "1.2.3.4" or hostname, e.g. "https:// ..."
/// https://testnet.seed.thorchain.info
public typealias ThorNode = String

/// Midgard API response objects
public struct Midgard {}

public protocol MidgardAPIResponse: Decodable {}
public protocol MidgardAPIResponseAsArray: Decodable {}

/// Arrays of MidgardAPIResponseAsArray conforming objects are a valid Midgard API response.
extension Array: MidgardAPIResponse where Element: MidgardAPIResponseAsArray {}

// {
//    "chain": "ETH",
//    "pub_key": "tthorpub1addwnpepqvvxqcz2azdxvrudd93yp6xutf3j76yvw3zup4xpf34vn3knl8nmcy9v8a9",
//    "address": "0xf5c9ba94e1eff689f1ffa318d0229fb25351d66d",
//    "router": "0xe0a63488e677151844e70623533c22007dc57c9e",
//    "halted": false
// }

/// Inbound Address data returned from Midgard. We deliberately do not conform to MidgardAPIResponse because this API is called differently against multiple endpoints for security.
public extension Midgard {
    /// Represents a Midgard inbound address object containing details of vault as returned by `/thorchain/inbound_addresses`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetProxiedInboundAddresses
    struct InboundAddress: Hashable, Decodable, Equatable, Comparable {
        static let runeNative = InboundAddress(chain: "THOR", pub_key: "", address: "", router: "", halted: false, global_trading_paused: false, chain_trading_paused: false, chain_lp_actions_paused: false, gas_rate: "", gas_rate_units: "", outbound_tx_size: "", outbound_fee: "", dust_threshold: "")

        /// Chain, e.g. "ETH"
        public let chain: String

        /// Public key
        public let pub_key: String

        /// Inbound Vault address. Only valid for a short period of time (~15 mins) due to vault churn. Do not cache.
        public let address: String

        /// If set, contains ETH router contract address which should be used with the .deposit() function.
        public let router: String?

        /// If set and true, indicates we should NOT use this chain.
        public let halted: Bool?

        public let global_trading_paused: Bool?
        public let chain_trading_paused: Bool?
        public let chain_lp_actions_paused: Bool?

        /// Estimate of gas rates to use for client transactions. Sats per byte or Gwei depending on chain.
        public let gas_rate: String
        public let gas_rate_units: String?

        public let outbound_tx_size: String?
        public let outbound_fee: String?
        public let dust_threshold: String?

        public static func <(lhs: InboundAddress, rhs: InboundAddress) -> Bool {
            lhs.chain < rhs.chain
        }

        public static func ==(lhs: InboundAddress, rhs: InboundAddress) -> Bool {
            lhs.chain == rhs.chain &&
                lhs.pub_key == rhs.pub_key &&
                lhs.address == rhs.address &&
                lhs.router == rhs.router
        }
    }
}

extension Array where Element == Midgard.InboundAddress {
    public func same(_ second: [Element]) -> Bool {
        sorted() == second.sorted()
    }
}

// {
//    "asset": "ETH.USDT-0X62E273709DA575835C7F6AEF4A31140CA5B1D190",
//    "assetDepth": "75858246300",
//    "assetPrice": "4.004465560166793",
//    "assetPriceUSD": "23.80014672779929",
//    "poolAPY": "0.0000655523609780495",
//    "runeDepth": "303771734763",
//    "status": "available",
//    "units": "56506730635",
//    "volume24h": "101341479104"
// }

public extension Midgard {
    enum PoolStatus: String, Decodable {
        case available, staged, suspended
    }

    /// Pool data returned from Midgard `/pools` and `/pool/{asset}`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetPools
    struct Pool: MidgardAPIResponse, MidgardAPIResponseAsArray {
        /// Asset type, e.g. "BNB.BNB" or "ETH.USDT-0X62E273709DA575835C7F6AEF4A31140CA5B1D190" (CAPS)
        public let asset: String
        public let decimals: Int?
        public let status: String
        public let pending_inbound_asset: String
        public let pending_inbound_rune: String
        public let balance_asset: String
        public let balance_rune: String
        public let pool_units: String
        public let LP_units: String
        public let synth_units: String
        public let synth_supply: String
        public let savers_depth: String
        public let savers_units: String
        public let synth_mint_paused: Bool
        public let synth_supply_remaining: String
        public let loan_collateral: String
        public let loan_cr: String
        public let derived_depth_bps: String

        var isActive: Bool {
            status.lowercased() == "available"
        }
    }
}

extension Array where Element == Midgard.Pool {
    func get(_ memo: String) throws -> Element {
        guard let pool = first(where: { $0.asset.uppercased() == memo.uppercased() }) else {
            throw Thorchain.SwapError.cantFoundPool(memo: memo.uppercased())
        }
        return pool
    }
}

// {
//    "database": true,
//    "inSync": true,
//    "scannerHeight": "107710"
// }

public extension Midgard {
    /// Midgard `/health` response
    /// https://testnet.midgard.thorchain.info/doc#operation/GetHealth
    struct HealthInfo: MidgardAPIResponse {
        /// True means healthy, connected to database
        public let database: Bool

        /// The current block count (int64 as String)
        public let scannerHeight: String

        /// True means healthy. False means Midgard is still catching up to the chain
        public let inSync: Bool
    }
}

public extension Midgard {
    enum PoolPeriod: String {
        case oneHour = "1h", oneDay = "24h", oneWeek = "7d", thirtyDays = "30d", ninetyDays = "90d", oneYear = "365d", all
    }

    /// Midgard `/pool/{asset}/stats` response
    /// https://testnet.midgard.thorchain.info/doc#operation/GetPoolStats
    struct PoolStatistics: MidgardAPIResponse {
        /// Asset
        public let asset: String

        /// The state of the pool, e.g. "available", "staged". Case is undefined.
        public let status: String

        /// Price of asset in rune. I.e. rune amount / asset amount. (Float as String)
        public let assetPrice: String

        /// The price of asset in USD (based on the deepest USD pool). (Float as String)
        public let assetPriceUSD: String

        /// The amount of Asset in the pool (Int64 as String)
        public let assetDepth: String

        /// The amount of Rune in the pool. (Int64 as String)
        public let runeDepth: String

        /// Liquidity Units in the pool. (Int64 as String)
        public let units: String

        /// Same as history/swaps:toAssetVolume (Int64 as String)
        public let toAssetVolume: String

        /// Same as history/swaps:toRuneVolume (Int64 to String)
        public let toRuneVolume: String

        /// Same as history/swaps:totalVolume (Int64 to String)
        public let swapVolume: String

        /// Same as history/swaps:toAssetCount (Int64 to String)
        public let toAssetCount: String

        /// Same as history/swaps:toRuneCount (Int64 to String)
        public let toRuneCount: String

        /// Same as history/swaps:totalCount (Int64 to String)
        public let swapCount: String

        /// Number of unique adresses that initiated swaps transactions in the period. (Int64 to String)
        public let uniqueSwapperCount: String

        /// (Basis points, 0-10000, where 10000=100%), same as history/swaps:toAssetAverageSlip (Double as String)
        public let toAssetAverageSlip: String

        /// (Basis points, 0-10000, where 10000=100%), same as history/swaps:toRuneAverageSlip (Double as String)
        public let toRuneAverageSlip: String

        /// (Basis points, 0-10000, where 10000=100%), same as history/swaps:averageSlip (Double as String)
        public let averageSlip: String

        /// Same as history/swaps:toAssetFees (Int64 as String)
        public let toAssetFees: String

        /// Same as history/swaps:toRuneFees (Int64 as String)
        public let toRuneFees: String

        /// Same as history/swaps:totalFees (Int64 as String)
        public let totalFees: String

        /// Average Percentage Yield: annual return estimated using last weeks income, taking compound interest into account (Float as String)
        public let poolAPY: String

        /// Same as history/liquidity_changes:addAssetLiquidityVolume (Int64 as String)
        public let addAssetLiquidityVolume: String

        /// Same as history/liquidity_changes:addRuneLiquidityVolume (Int64 as String)
        public let addRuneLiquidityVolume: String

        /// Same as history/liquidity_changes:addLiquidityVolume (Int64 as String)
        public let addLiquidityVolume: String

        /// Same as history/liquidity_changes:addLiquidityCount (Int64 as String)
        public let addLiquidityCount: String

        /// Same as history/liquidity_changes:withdrawAssetVolume (Int64 as String)
        public let withdrawAssetVolume: String

        /// Same as history/liquidity_changes:withdrawRuneVolume (Int64 as String)
        public let withdrawRuneVolume: String

        /// Same as history/liquidity_changes:withdrawVolume (Int64 as String)
        public let withdrawVolume: String

        /// Same as history/liquidity_changes:withdrawCount (Int64 as String)
        public let withdrawCount: String

        /// same as len(history/members?pool=POOL) (Int64 as String)
        public let uniqueMemberCount: String
    }
}

// {
//    "intervals": [
//        {
//            "assetDepth": "268688067",
//            "assetPrice": "11700.550828094647",
//            "assetPriceUSD": "61736.29379568968",
//            "endTime": "1616115951",
//            "liquidityUnits": "2256163166061",
//            "runeDepth": "3143798384836",
//            "startTime": "1615526787"
//        }
//    ],
//    "meta": {
//        "endTime": "1616115951",
//        "startTime": "1615526787"
//    }
// }
public extension Midgard {
    enum HistoryInterval: String {
        case fiveMinutes = "5min", hour, day, week, month, quarter, year
    }
}

public extension Midgard {
    /// Depth and Price History from `/history/depths/{pool}`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetDepthHistory
    struct PriceDepthHistory: MidgardAPIResponse {
        public struct DepthHistoryInterval: Decodable {
            /// The amount of Asset in the pool at the end of the interval (Int64 as String)
            public let assetDepth: String

            /// Price of asset in rune. I.e. rune amount / asset amount (Float as String)
            public let assetPrice: String

            /// The price of asset in USD (based on the deepest USD pool). (Float as String)
            public let assetPriceUSD: String

            /// The end time of bucket in unix timestamp (Int64 as String)
            public let endTime: String

            /// Liquidity Units in the pool at the end of the interval (Int64 as String)
            public let liquidityUnits: String

            /// The amount of Rune in the pool at the end of the interval (Int64 as String)
            public let runeDepth: String

            /// The beginning time of bucket in unix timestamp (Int64 as String)
            public let startTime: String
        }

        public struct DepthHistoryMeta: Decodable {
            /// The beginning time of bucket in unix timestamp (Int64 as String)
            public let startTime: String

            /// The end time of bucket in unix timestamp (Int64 as String)
            public let endTime: String
        }

        public let intervals: [DepthHistoryInterval]
        public let meta: DepthHistoryMeta
    }
}

// {
//    "intervals": [],
//    "meta": {
//        "avgNodeCount": "4.26",
//        "blockRewards": "284084912428",
//        "bondingEarnings": "548051751804",
//        "earnings": "548757218710",
//        "endTime": "1616117269",
//        "liquidityEarnings": "705466906",
//        "liquidityFees": "264672306282",
//        "pools": [
//            {
//                "assetLiquidityFees": "24294631802",
//                "earnings": "73093367",
//                "pool": "BNB.BUSD-74E",
//                "rewards": "-4109012975",
//                "runeLiquidityFees": "168",
//                "totalLiquidityFeesRune": "4182106342"
//            },
//            {
//                "assetLiquidityFees": "17717934",
//                "earnings": "24891370",
//                "pool": "ETH.ETH",
//                "rewards": "-17369398420",
//                "runeLiquidityFees": "13752726654",
//                "totalLiquidityFeesRune": "17394289790"
//            },
//            {
//                "assetLiquidityFees": "1745386300",
//                "earnings": "160876373",
//                "pool": "BTC.BTC",
//                "rewards": "-96832326936",
//                "runeLiquidityFees": "82767866094",
//                "totalLiquidityFeesRune": "96993203309"
//            },
//            {
//                "assetLiquidityFees": "6757406791",
//                "earnings": "11508359",
//                "pool": "BNB.BNB",
//                "rewards": "-40687367407",
//                "runeLiquidityFees": "6130630113",
//                "totalLiquidityFeesRune": "40698875766"
//            },
//            {
//                "assetLiquidityFees": "539744721",
//                "earnings": "204576268",
//                "pool": "LTC.LTC",
//                "rewards": "-27634275684",
//                "runeLiquidityFees": "10214067847",
//                "totalLiquidityFeesRune": "27838851952"
//            },
//            {
//                "assetLiquidityFees": "455164084",
//                "earnings": "3439721",
//                "pool": "BNB.USDT-DC8",
//                "rewards": "-69300056",
//                "runeLiquidityFees": "0",
//                "totalLiquidityFeesRune": "72739777"
//            },
//            {
//                "assetLiquidityFees": "18022485",
//                "earnings": "5913534",
//                "pool": "BCH.BCH",
//                "rewards": "-1912982542",
//                "runeLiquidityFees": "0",
//                "totalLiquidityFeesRune": "1918896076"
//            },
//            {
//                "assetLiquidityFees": "73754427902",
//                "earnings": "219575432",
//                "pool": "ETH.USDT-0X62E273709DA575835C7F6AEF4A31140CA5B1D190",
//                "rewards": "-73301753842",
//                "runeLiquidityFees": "6781115004",
//                "totalLiquidityFeesRune": "73521329274"
//            },
//            {
//                "assetLiquidityFees": "13260598506",
//                "earnings": "1592482",
//                "pool": "BNB.BUSD-BAF",
//                "rewards": "-2050421514",
//                "runeLiquidityFees": "595907",
//                "totalLiquidityFeesRune": "2052013996"
//            }
//        ],
//        "startTime": "1615526787"
//    }
// }
public extension Midgard {
    /// Earnings History from `v2/history/earnings`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetEarningsHistory
    struct EarningsHistory: MidgardAPIResponse {
        public struct EarningsHistoryItem: Decodable {
            public struct EarningsHistoryItemPool: Decodable {
                /// asset for the given pool
                public let pool: String

                /// Liquidity fees collected in the pool's asset (Int64 (10^8) as String)
                public let assetLiquidityFees: String

                /// Liquidity fees collected in RUNE (Int64 (10^8) as String)
                public let runeLiquidityFees: String

                /// Total liquidity fees (assetFees + runeFees) collected, shown in RUNE (Int64 (10^8) as String)
                public let totalLiquidityFeesRune: String

                /// RUNE amount sent to (positive) or taken from (negative) the pool as a result of balancing it's share of system income each block (Int64 (10^8) as String)
                public let rewards: String

                /// Total earnings in RUNE (totalLiquidityFees + rewards)  (Int64 (10^8) as String)
                public let earnings: String
            }

            /// The beginning time of bucket in unix timestamp (Int64 as String)
            public let startTime: String

            /// The end time of bucket in unix timestamp (Int64 as String)
            public let endTime: String

            /// Total liquidity fees, converted to RUNE, collected during the time interval (Int64 as String)
            public let liquidityFees: String

            /// Total block rewards emitted during the time interval (Int64 as String)
            public let blockRewards: String

            /// System income generated during the time interval. It is the sum of liquidity fees and block rewards (Int64 as String)
            public let earnings: String

            /// Share of earnings sent to nodes during the time interval (Int64 as String)
            public let bondingEarnings: String

            /// Share of earnings sent to pools during the time interval
            public let liquidityEarnings: String

            /// Average amount of active nodes during the time interval
            public let avgNodeCount: String

            /// Earnings data for each pool for the time interval
            public let pools: [EarningsHistoryItemPool]
        }

        public let intervals: [EarningsHistoryItem]
        public let meta: EarningsHistoryItem
    }
}

// {
//    "intervals": [],
//    "meta": {
//        "averageSlip": "248.66425992779784",
//        "endTime": "1616120436",
//        "startTime": "1615526787",
//        "toAssetAverageSlip": "258.0693641618497",
//        "toAssetCount": "173",
//        "toAssetFees": "145031601734",
//        "toAssetVolume": "1881241359035",
//        "toRuneAverageSlip": "233.01923076923077",
//        "toRuneCount": "104",
//        "toRuneFees": "119647001787",
//        "toRuneVolume": "1314209544908",
//        "totalCount": "277",
//        "totalFees": "264678603521",
//        "totalVolume": "3195450903943"
//    }
// }
public extension Midgard {
    /// Swaps History from Midgard `/history/swaps`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetSwapHistory
    struct SwapsHistory: MidgardAPIResponse {
        /// Swap History Item
        public struct SwapHistoryItem: Decodable {
            /// The beginning time of bucket in unix timestamp (Int64 as String)
            public let startTime: String

            /// The end time of bucket in unix timestamp (Int64 as String)
            public let endTime: String

            /// Count of swaps from RUNE to asset (Int64 as String)
            public let toAssetCount: String

            /// count of swaps from asset to rune (Int64 as String)
            public let toRuneCount: String

            /// toAssetCount + toRuneCount (Int64 as String)
            public let totalCount: String

            /// volume of swaps from rune to asset denoted in rune (Int64 as String)
            public let toAssetVolume: String

            /// volume of swaps from asset to rune denoted in rune (Int64 as String)
            public let toRuneVolume: String

            /// toAssetVolume + toRuneVolume (denoted in rune) (Int64 as String)
            public let totalVolume: String

            /// the fees collected from swaps to asset denoted in rune (Int64 as String)
            public let toAssetFees: String

            /// the fees collected from swaps to rune (Int64 as String)
            public let toRuneFees: String

            ///  the sum of all fees collected denoted in rune (Int64 as String)
            public let totalFees: String

            /// (Basis points, 0-10000, where 10000=100%), the average slip for swaps to asset. Big swaps have the same weight as small swaps (Double as String)
            public let toAssetAverageSlip: String

            /// (Basis points, 0-10000, where 10000=100%), the average slip for swaps to rune. Big swaps have the same weight as small swaps (Double as String)
            public let toRuneAverageSlip: String

            /// (Basis points, 0-10000, where 10000=100%), the average slip by swap. Big swaps have the same weight as small swaps (Double as String)
            public let averageSlip: String
        }

        public let meta: SwapHistoryItem
        public let intervals: [SwapHistoryItem]
    }
}

// {
//    "intervals": [],
//    "meta": {
//        "addAssetLiquidityVolume": "6459564483218",
//        "addLiquidityCount": "81",
//        "addLiquidityVolume": "14705516727792",
//        "addRuneLiquidityVolume": "8245952244574",
//        "endTime": "1616120911",
//        "net": "13619843673223",
//        "startTime": "1615526787",
//        "withdrawAssetVolume": "542225656680",
//        "withdrawCount": "13",
//        "withdrawRuneVolume": "543447397889",
//        "withdrawVolume": "1085673054569"
//    }
// }

public extension Midgard {
    /// Liquidity Changes History from Midgard `/history/liquidity_changes`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetLiquidityHistory
    struct LiquidityHistory: MidgardAPIResponse {
        /// Liquidity History Item
        public struct LiquidityHistoryItem: Decodable {
            /// The beginning time of bucket in unix timestamp (Int64 as String)
            public let startTime: String

            /// The end time of bucket in unix timestamp (Int64 as String)
            public let endTime: String

            /// total assets deposited during the time interval. Denoted in Rune using the price at deposit time. (Int64 (10^8) as String)
            public let addAssetLiquidityVolume: String

            /// total Rune deposited during the time interval. (Int64 (10^8) as String)
            public let addRuneLiquidityVolume: String

            /// total of rune and asset deposits. Denoted in Rune (using the price at deposit time). (Int64 (10^8) as String)
            public let addLiquidityVolume: String

            /// number of deposits during the time interval. (Int64 as String)
            public let addLiquidityCount: String

            /// total assets withdrawn during the time interval. Denoted in Rune using the price at withdraw time. (Int64 (10^8) as String)
            public let withdrawAssetVolume: String

            /// total Rune withdrawn during the time interval. (Int64 (10^8) as String)
            public let withdrawRuneVolume: String

            /// total of rune and asset withdrawals. Denoted in Rune (using the price at withdraw time). (Int64 (10^8) as String)
            public let withdrawVolume: String

            /// number of withdraw during the time interval. (Int64 as String)
            public let withdrawCount: String

            /// net liquidity changes (withdrawals - deposits) during the time interval (Int64 as String)
            public let net: String
        }

        public let meta: LiquidityHistoryItem
        public let intervals: [LiquidityHistoryItem]
    }
}

// {
//    "ed25519": "tthorpub1addwnpepqgtua4mw2dt483y0f8ul8xv9l2k8s56pm7lzuuuc6q0revj94xtvcfcxg3c",
//    "nodeAddress": "tthor1f37lphn55vklw8kj6zxe28v05hrtpn9fd58cvm",
//    "secp256k1": "tthorpub1addwnpepqgtua4mw2dt483y0f8ul8xv9l2k8s56pm7lzuuuc6q0revj94xtvcfcxg3c"
// }

public extension Midgard {
    /// Nodes List from `/nodes`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetNodes
    struct Node: MidgardAPIResponseAsArray {
        /// node thorchain address
        public let nodeAddress: String

        /// secp256k1 public key
        public let secp256k1: String

        /// ed25519 public key
        public let ed25519: String
    }
}

// {
//    "activeBonds": [
//        "1013921315297",
//        "1015636112556",
//        "1060409834838",
//        "1092449664701",
//        "1122196867175",
//        "1322393353216",
//        "1413029590077"
//    ],
//    "activeNodeCount": "7",
//    "blockRewards": {
//        "blockReward": "2626008",
//        "bondReward": "2607630",
//        "poolReward": "18377"
//    },
//    "bondMetrics": {
//        "averageActiveBond": "1148576676837",
//        "averageStandbyBond": "505400000000",
//        "maximumActiveBond": "1413029590077",
//        "maximumStandbyBond": "1000900000000",
//        "medianActiveBond": "1092449664701",
//        "medianStandbyBond": "1000900000000",
//        "minimumActiveBond": "1013921315297",
//        "minimumStandbyBond": "9900000000",
//        "totalActiveBond": "8040036737860",
//        "totalStandbyBond": "1010800000000"
//    },
//    "bondingAPY": "36.26175916878339",
//    "liquidityAPY": "0.013477508676138283",
//    "nextChurnHeight": "108842",
//    "poolActivationCountdown": "849",
//    "poolShareFactor": "0.006998352794382449",
//    "standbyBonds": [
//        "9900000000",
//        "1000900000000"
//    ],
//    "standbyNodeCount": "2",
//    "totalPooledRune": "7928284790272",
//    "totalReserve": "99442572418968"
// }
public extension Midgard {
    /// Nodes List from `/network`
    /// https://testnet.midgard.thorchain.info/doc#operation/GetNetworkData
    struct NetworkData: MidgardAPIResponse {
        /// Bond Metrics
        public struct BondMetrics: Decodable {
            /// Total bond of active nodes (Int64 as String)
            public let totalActiveBond: String

            /// Average bond of active nodes
            public let averageActiveBond: String

            /// Median bond of active nodes
            public let medianActiveBond: String

            /// Minumum bond of active nodes
            public let minimumActiveBond: String

            /// Maxinum bond of active nodes
            public let maximumActiveBond: String

            /// Total bond of standby nodes
            public let totalStandbyBond: String

            /// Average bond of standby nodes
            public let averageStandbyBond: String

            /// Median bond of standby nodes
            public let medianStandbyBond: String

            /// Minumum bond of standby nodes
            public let minimumStandbyBond: String

            /// Maximum bond of standby nodes
            public let maximumStandbyBond: String
        }

        /// Block Reward
        public struct BlockRewards: Decodable {
            public let blockReward: String
            public let bondReward: String
            public let poolReward: String
        }

        public let bondMetrics: BondMetrics
        public let blockRewards: BlockRewards

        /// Active bonds (Int64 as String)
        public let activeBonds: [String]

        /// Standby bonds (Int64 as String)
        public let standbyBonds: [String]

        /// Number of Active Nodes (Int64 as String)
        public let activeNodeCount: String

        /// Number of Standby Nodes (Int64 as String)
        public let standbyNodeCount: String

        /// Total Rune pooled in all pools (Int64 as String)
        public let totalPooledRune: String

        /// Total left in Reserve (Int64 as String)
        public let totalReserve: String

        /// next height of blocks (Int64 as String)
        public let nextChurnHeight: String

        /// The remaining time of pool activation (in blocks) (Int64 as String)
        public let poolActivationCountdown: String

        public let poolShareFactor: String

        /// (1 + (bondReward * blocksPerMonth/totalActiveBond)) ^ 12 -1 (Float as String)
        public let bondingAPY: String

        /// (1 + (stakeReward * blocksPerMonth/totalDepth of active pools)) ^ 12 -1 (Float as String)
        public let liquidityAPY: String
    }
}

// {
//    "actions": [
//        {
//            "date": "1616120281068771800",
//            "height": "108861",
//            "in": [
//                {
//                    "address": "tthor1ylvukzdfzqjn4gt02xpnsy7fd8l6y6sufh5t4z",
//                    "coins": [
//                        {
//                            "amount": "2138700000",
//                            "asset": "THOR.RUNE"
//                        }
//                    ],
//                    "txID": "3E4E3EB63809EC1C777387F4C3E728B7657ABF71CC257099AA6F7CA9EC201A92"
//                }
//            ],
//            "metadata": {
//                "swap": {
//                    "liquidityFee": "6297239",
//                    "networkFees": [],
//                    "tradeSlip": "30",
//                    "tradeTarget": "0"
//                }
//            },
//            "out": [
//                {
//                    "address": "tthor1v8ppstuf6e3x0r4glqc68d5jqcs2tf38ulmsrp",
//                    "coins": [
//                        {
//                            "amount": "13886469",
//                            "asset": "BNB/BNB"
//                        }
//                    ],
//                    "txID": "0000000000000000000000000000000000000000000000000000000000000000"
//                }
//            ],
//            "pools": [
//                "BNB.BNB"
//            ],
//            "status": "success",
//            "type": "swap"
//        }
//    ],
//    "count": "348"
// }
public extension Midgard {
    enum ActionType: String {
        case swap, addLiquidity, withdraw, donate, refund
    }

    /// Actions List from Midgard `/actions` API
    /// https://testnet.midgard.thorchain.info/doc#operation/GetActions
    struct ActionsList: MidgardAPIResponse {
        public struct Action: Decodable {
            /// Type of Action
            public enum ActionType: String, Decodable {
                case swap, addLiquidity, withdraw, donate, refund
            }

            public enum ActionStatus: String, Decodable {
                case success, pending
            }

            public struct Transaction: Decodable {
                public struct Coin: Decodable {
                    /// Asset in CHAIN.SYMBOL format
                    public let asset: String

                    /// Asset Amount (Int64 (10^8) as String)
                    public let amount: String
                }

                /// Transaction id hash. Some transactions (such as outbound transactions made in the native asset) may have a zero value.
                public let txID: String

                /// Sender address
                public let address: String

                public let coins: [Coin]
            }

            public struct Metadata: Decodable {
                public struct SwapMetadata: Decodable {
                    public struct NetworkFee: Decodable {
                        /// Asset in CHAIN.SYMBOL format
                        public let asset: String

                        /// Asset Amount (Int64 (10^8) as String)
                        public let amount: String
                    }

                    /// List of network fees associated to an action. One network fee is charged for each outbound transaction
                    public let networkFees: [NetworkFee]

                    /// RUNE amount charged as swap liquidity fee (Int64 (10^8) as String)
                    public let liquidityFee: String

                    /// (Basis points, 0-10000, where 10000=100%), swap slip percentage (Int64 as String)
                    public let swapSlip: String

                    /// minimum output amount specified for the swap (Int64 (10^8) as String)
                    public let swapTarget: String
                }

                public struct AddLiquidityMetadata: Decodable {
                    /// amount of liquidity units assigned to the member as result of the liquidity deposit (Int64 as String)
                    public let liquidityUnits: String
                }

                public struct WithdrawMetadata: Decodable {
                    public struct NetworkFee: Decodable {
                        /// Asset in CHAIN.SYMBOL format
                        public let asset: String

                        /// Asset Amount (Int64 (10^8) as String)
                        public let amount: String
                    }

                    /// amount of liquidity units removed from the member as result of the withdrawal (Int64 as String)
                    public let liquidityUnits: String

                    /// (-1.0 <=> 1.0), indicates how assymetrical the withdrawal was. 0 means totally symetrical (Double as String)
                    public let asymmetry: String

                    /// (Basis points, 0-10000, where 10000=100%), percentage of total pool ownership withdrawn
                    public let basisPoints: String

                    /// List of network fees associated to an action. One network fee is charged for each outbound transaction
                    public let networkFees: [NetworkFee]
                }

                public struct RefundMetadata: Decodable {
                    public struct NetworkFee: Decodable {
                        /// Asset in CHAIN.SYMBOL format
                        public let asset: String

                        /// Asset Amount (Int64 (10^8) as String)
                        public let amount: String
                    }

                    /// List of network fees associated to an action. One network fee is charged for each outbound transaction
                    public let networkFees: [NetworkFee]

                    /// Reason for the refund
                    public let reason: String
                }

                public struct DonateMetadata: Decodable {
                    // TODO: awaiting https://midgard.thorchain.info/doc#operation/GetActions
                }

                public struct SwitchMetadata: Decodable {
                    // TODO: awaiting https://midgard.thorchain.info/doc#operation/GetActions
                }

                /// One of these six is present
                public let swap: SwapMetadata?
                public let addLiquidity: AddLiquidityMetadata?
                public let withdraw: WithdrawMetadata?
                public let refund: RefundMetadata?
                public let donate: DonateMetadata?
                public let `switch`: SwitchMetadata?
            }

            /// Pools involved in the action
            public let pools: [String]

            /// Type of action
            public let type: ActionType

            /// Indicates if the action is completed or if related outbound transactions are still pending.
            public let status: ActionStatus

            /// Inbound transactions related to the action
            public let `in`: [Transaction]

            /// Outbound transactions related to the action
            public let out: [Transaction]

            /// Unix timestamp for when the action was registered (Int64 as String)
            public let date: String

            /// block height at which the action was registered (Int64 as String)
            public let height: String

            public let metadata: Metadata
        }

        /// Number of results matching the given filters. (Int64 as String)
        public let count: String

        public let actions: [Action]
    }
}

public extension Midgard {
    /// Midgard Members from `/members` API
    /// https://testnet.midgard.thorchain.info/doc#operation/GetMembersAdresses
    typealias Member = String
}

extension Midgard.Member: MidgardAPIResponseAsArray {}

// {
//    "pools": [
//        {
//            "assetAdded": "1000000",
//            "assetAddress": "tb1q43m85z83kntdqw58cnxae2sdcehl79v7m0859e",
//            "assetWithdrawn": "0",
//            "dateFirstAdded": "1615904228",
//            "dateLastAdded": "1615904228",
//            "liquidityUnits": "7875083703",
//            "pool": "BTC.BTC",
//            "runeAdded": "10102977893",
//            "runeAddress": "tthor12ufgxfsch2xkwc9fjzrq86fm3tm8pgpd2rm5ta",
//            "runeWithdrawn": "0"
//        }
//    ]
// }
public extension Midgard {
    /// Midgard Member Detail from Midgard `/member/{address}` API
    /// https://testnet.midgard.thorchain.info/doc#operation/GetMemberDetail
    struct MemberDetail: MidgardAPIResponse {
        public struct MemberPool: Decodable {
            /// The Pool the rest of the data refers to
            public let pool: String

            /// rune address used by the member
            public let runeAddress: String

            /// asset address used by the member
            public let assetAddress: String

            /// pool liquidity units that belong the the member (Int64 as String)
            public let liquidityUnits: String

            /// total RUNE added to the pool by member (Int64 as String)
            public let runeAdded: String

            /// total asset added to the pool by member (Int64 as String)
            public let assetAdded: String

            /// total RUNE withdrawn from the pool by member (Int64 as String)
            public let runeWithdrawn: String

            /// total asset withdrawn from the pool by member (Int64 as String)
            public let assetWithdrawn: String

            /// Unix timestamp for the first time member deposited into the pool (Int64 as String)
            public let dateFirstAdded: String

            /// Unix timestamp for the last time member deposited into the pool (Int64 as String)
            public let dateLastAdded: String
        }

        /// List details of all the liquidity providers identified with the given address
        public let pools: [MemberPool]
    }
}

// {
//    "addLiquidityCount": "81",
//    "addLiquidityVolume": "14705516727792",
//    "dailyActiveUsers": "11",
//    "monthlyActiveUsers": "112",
//    "runeDepth": "7933523782911",
//    "runePriceUSD": "5.2763495066335135",
//    "swapCount": "368",
//    "swapCount24h": "26",
//    "swapCount30d": "368",
//    "swapVolume": "1989460437104",
//    "toAssetCount": "104",
//    "toRuneCount": "264",
//    "uniqueSwapperCount": "112",
//    "withdrawCount": "13",
//    "withdrawVolume": "1085673054569"
// }
public extension Midgard {
    /// Global Stats from Midgard `/stats` API}
    /// https://testnet.midgard.thorchain.info/doc#operation/GetStats
    struct GlobalStats: MidgardAPIResponse {
        /// current total Rune in the pools. (Int64 (10^8) as String)
        public let runeDepth: String

        /// the price of Rune based on the deepest USD pool. (Float as String)
        public let runePriceUSD: String

        /// total volume of swaps denoted in Rune since beginning. (Int64 as String)
        public let swapVolume: String

        /// number of swaps in the last 24h. (Int64 as String)
        public let swapCount24h: String

        /// number of swaps in the last 30d. (Int64 as String)
        public let swapCount30d: String

        /// number of swaps since beginning. (Int64 as String)
        public let swapCount: String

        /// number of swaps from Rune to Asset since beginning. (Int64 as String)
        public let toAssetCount: String

        /// number of swaps from Asset to Rune since beginning. (Int64 as String)
        public let toRuneCount: String

        /// unique users (addresses) initiating swaps in the last 24 hours. (Int64 as String)
        public let dailyActiveUsers: String

        /// unique users (addresses) initiating swaps in the last 30 days. (Int64 as String)
        public let monthlyActiveUsers: String

        /// unique users (addresses) initiating swaps since beginning. (Int64 as String)
        public let uniqueSwapperCount: String

        /// total of deposits since beginning. (Int64 (10^8) as String)
        public let addLiquidityVolume: String

        /// total of withdraws since beginning. (Int64 (10^8) as String)
        public let withdrawVolume: String

        /// number of deposits since beginning. (Int64 as String)
        public let addLiquidityCount: String

        /// number of withdraws since beginning (Int64 as String)
        public let withdrawCount: String
    }
}

// {
//    "int_64_values": {
//        "AsgardSize": 6,
//        "BadValidatorRate": 2048,
//        "BadValidatorRedline": 3,
//        "BlocksPerYear": 6311390,
//        "ChurnInterval": 240,
//        "ChurnRetryInterval": 720,
//        "CliTxCost": 0,
//        "DesiredValidatorSet": 30,
//        "DoubleSignMaxAge": 24,
//        "EmissionCurve": 6,
//        "FailKeygenSlashPoints": 720,
//        "FailKeysignSlashPoints": 2,
//        "FullImpLossProtectionBlocks": 1728000,
//        "FundMigrationInterval": 360,
//        "IncentiveCurve": 100,
//        "JailTimeKeygen": 4320,
//        "JailTimeKeysign": 60,
//        "LackOfObservationPenalty": 2,
//        "LiquidityLockUpBlocks": 0,
//        "MaxAvailablePools": 100,
//        "MaxSwapsPerBlock": 100,
//        "MinRunePoolDepth": 10000000000,
//        "MinSlashPointsForBadValidator": 100,
//        "MinSwapsPerBlock": 10,
//        "MinimumBondInRune": 1000000000000,
//        "MinimumNodesForBFT": 4,
//        "MinimumNodesForYggdrasil": 6,
//        "NativeTransactionFee": 2000000,
//        "ObservationDelayFlexibility": 10,
//        "ObserveSlashPoints": 1,
//        "OldValidatorRate": 2048,
//        "OutboundTransactionFee": 2000000,
//        "PoolCycle": 1000,
//        "SigningTransactionPeriod": 300,
//        "StagedPoolCost": 1000000000,
//        "VirtualMultSynths": 2,
//        "YggFundLimit": 50
//    },
//    "bool_values": {
//        "StrictBondLiquidityRatio": false
//    },
//    "string_values": {
//        "DefaultPoolStatus": "Staged"
//    }
// }
public extension Thorchain {
    /// Thorchain constants from Midgard `/thorchain/constants` API
    /// https://testnet.midgard.thorchain.info/doc#operation/GetProxiedInboundAddresses
    struct Constants: MidgardAPIResponse {
        public struct Int64Constants: Decodable {
            public let AsgardSize: Int
            public let BadValidatorRate: Int
            public let BadValidatorRedline: Int
            public let BlocksPerYear: Int
            public let ChurnInterval: Int
            public let ChurnRetryInterval: Int
            public let CliTxCost: Int? // Not present in Mainnet
            public let DesiredValidatorSet: Int
            public let DoubleSignMaxAge: Int
            public let EmissionCurve: Int
            public let FailKeygenSlashPoints: Int
            public let FailKeysignSlashPoints: Int
            public let FullImpLossProtectionBlocks: Int
            public let FundMigrationInterval: Int
            public let IncentiveCurve: Int
            public let JailTimeKeygen: Int
            public let JailTimeKeysign: Int
            public let LackOfObservationPenalty: Int
            public let LiquidityLockUpBlocks: Int
            public let MaxAvailablePools: Int
            public let MaxSwapsPerBlock: Int
            public let MinRunePoolDepth: Int
            public let MinSlashPointsForBadValidator: Int
            public let MinSwapsPerBlock: Int
            public let MinimumBondInRune: Int
            public let MinimumNodesForBFT: Int
            public let MinimumNodesForYggdrasil: Int
            public let NativeTransactionFee: Int
            public let ObservationDelayFlexibility: Int
            public let ObserveSlashPoints: Int
            public let OldValidatorRate: Int
            public let OutboundTransactionFee: Int
            public let PoolCycle: Int
            public let SigningTransactionPeriod: Int
            public let StagedPoolCost: Int? // Not present on Mainnet
            public let VirtualMultSynths: Int
            public let YggFundLimit: Int
        }

        public struct BoolConstants: Decodable {
            public let StrictBondLiquidityRatio: Bool
        }

        public struct StringConstants: Decodable {
            public let DefaultPoolStatus: String
        }

        public let int_64_values: Int64Constants
        public let bool_values: BoolConstants
        public let string_values: StringConstants
    }
}

// [
//    {
//        "chain": "BCH",
//        "last_observed_in": 1438403,
//        "last_signed_out": 108578,
//        "thorchain": 109563
//    },
//    {
//        "chain": "BNB",
//        "last_observed_in": 9969246,
//        "last_signed_out": 108578,
//        "thorchain": 109563
//    },
//    {
//        "chain": "BTC",
//        "last_observed_in": 1940760,
//        "last_signed_out": 108578,
//        "thorchain": 109563
//    },
//    {
//        "chain": "ETH",
//        "last_observed_in": 9863664,
//        "last_signed_out": 108578,
//        "thorchain": 109563
//    },
//    {
//        "chain": "LTC",
//        "last_observed_in": 1843882,
//        "last_signed_out": 108578,
//        "thorchain": 109563
//    }
// ]
public extension Thorchain {
    /// Thorchain last block information from Midgard `/thorchain/lastblock` API
    /// https://testnet.midgard.thorchain.info/doc#operation/GetProxiedLastblock
    struct LastBlock: MidgardAPIResponseAsArray {
        public let chain: String
        public let last_observed_in: Int
        public let last_signed_out: Int
        public let thorchain: Int
    }
}

// {
//    "swap": 0,
//    "outbound": 0,
//    "internal": 0
// }
public extension Thorchain {
    /// Queue endpoint from Thorchain Midgard `/thorchain/queue` API
    /// https://testnet.midgard.thorchain.info/doc#operation/GetProxiedQueue
    struct Queue: MidgardAPIResponse {
        public let swap: Int
        public let outbound: Int
        public let `internal`: Int
    }
}
