import Foundation
import Crypto
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class BinanceCexProvider {
    private static let baseUrl = "https://api.binance.com"

    private let networkManager: NetworkManager
    private let apiKey: String
    private let secret: String

    init(networkManager: NetworkManager, apiKey: String, secret: String) {
        self.networkManager = networkManager
        self.apiKey = apiKey
        self.secret = secret
    }

    private func coinUidMap() async throws -> [String: String] {
        [
            "1INCH": "1inch",
            "AAVE": "aave",
            "ACA": "acala",
            "ACH": "alchemy-pay",
            "ACM": "ac-milan-fan-token",
            "ADA": "cardano",
            "ADX": "adex",
            "AERGO": "aergo",
            "AGIX": "singularitynet",
            "AGLD": "adventure-gold",
            "AKRO": "akropolis",
            "ALCX": "alchemix",
            "ALGO": "algorand",
            "ALICE": "my-neighbor-alice",
            "ALPACA": "alpaca-finance",
            "ALPHA": "alpha-finance",
            "ALPINE": "alpine-f1-team-fan-token",
            "AMB": "amber",
            "AMP": "amp-token",
            "ANKR": "ankr",
            "ANT": "aragon",
            "APE": "apecoin-ape",
            "API3": "api3",
            "APT": "aptos",
            "AR": "arweave",
            "ARB": "arbitrum",
            "ARDR": "ardor",
            "ARK": "ark",
            "ARPA": "arpa",
            "ASR": "as-roma-fan-token",
            "AST": "airswap",
            "ASTR": "astar",
            "ATA": "automata",
            "ATM": "atletico-madrid",
            "ATOM": "cosmos",
            "AUCTION": "auction",
            "AUDIO": "audius",
            "AUTO": "cube",
            "AVA": "concierge-io",
            "AVAX": "avalanche-2",
            "AXS": "axie-infinity",
            "BADGER": "badger-dao",
            "BAKE": "bakerytoken",
            "BAL": "balancer",
            "BAND": "band-protocol",
            "BAR": "fc-barcelona-fan-token",
            "BAT": "basic-attention-token",
            "BCH": "bitcoin-cash",
            "BDOT": "babydot",
            "BEL": "bella-protocol",
            "BETA": "beta-finance",
            "BETH": "binance-eth",
            "BICO": "biconomy",
            "BIDR": "binanceidr",
            "BIFI": "beefy-finance",
            "BLZ": "bluzelle",
            "BNB": "binancecoin",
            "BNC": "bifrost-native-coin",
            "BNT": "bancor",
            "BNX": "binaryx",
            "BOND": "barnbridge",
            "BSW": "biswap",
            "BTC": "bitcoin",
            "BTS": "bitshares",
            "BTTOLD": "bittorrent-old",
            "BURGER": "burger-swap",
            "BUSD": "binance-usd",
            "C98": "coin98",
            "CAKE": "pancakeswap-token",
            "CAN": "channels",
            "CELO": "celo",
            "CELR": "celer-network",
            "CFX": "conflux-token",
            "CHESS": "tranchess",
            "CHR": "chromaway",
            "CHZ": "chiliz",
            "CITY": "manchester-city-fan-token",
            "CKB": "nervos-network",
            "CLV": "clover-finance",
            "COCOS": "cocos-bcx",
            "COMBO": "furucombo",
            "COMP": "compound-governance-token",
            "COS": "contentos",
            "COTI": "coti",
            "CREAM": "cream-2",
            "CRV": "curve-dao-token",
            "CTK": "certik",
            "CTSI": "cartesi",
            "CTXC": "cortex",
            "CVC": "civic",
            "CVP": "concentrated-voting-power",
            "CVX": "convex-finance",
            "DAI": "dai",
            "DAR": "mines-of-dalarnia",
            "DASH": "dash",
            "DATA": "streamr",
            "DCR": "decred",
            "DEGO": "dego-finance",
            "DENT": "dent",
            "DEXE": "dexe",
            "DF": "dforce-token",
            "DGB": "digibyte",
            "DIA": "dia-data",
            "DOCK": "dock",
            "DODO": "dodo",
            "DOGE": "dogecoin",
            "DOT": "polkadot",
            "DREP": "drep-new",
            "DUSK": "dusk-network",
            "DYDX": "dydx",
            "EDU": "edu-coin",
            "EFI": "efinity",
            "EGLD": "elrond-erd-2",
            "ELF": "aelf",
            "ENJ": "enjincoin",
            "ENS": "ethereum-name-service",
            "EOS": "eos",
            "EPS": "ellipsis",
            "ERN": "ethernity-chain",
            "ETC": "ethereum-classic",
            "ETH": "ethereum",
            "ETHDOWN": "ethdown",
            "ETHUP": "ethup",
            "ETHW": "ethereum-pow-iou",
            "EVX": "everex",
            "FARM": "harvest-finance",
            "FET": "fetch-ai",
            "FIDA": "bonfida",
            "FIL": "filecoin",
            "FIO": "fio-protocol",
            "FIRO": "zcoin",
            "FIS": "stafi",
            "FLM": "flamingo-finance",
            "FLOKI": "floki",
            "FLOW": "flow",
            "FLR": "flare-networks",
            "FLUX": "zelcash",
            "FOR": "force-protocol",
            "FORTH": "ampleforth-governance-token",
            "FRONT": "frontier-token",
            "FTM": "fantom",
            "FTT": "ftx-token",
            "FUN": "funfair",
            "FXS": "frax-share",
            "GAL": "project-galaxy",
            "GALA": "gala",
            "GAS": "gas",
            "GFT": "game-fantasy-token",
            "GHST": "aavegotchi",
            "GLM": "golem",
            "GLMR": "moonbeam",
            "GMT": "stepn",
            "GMX": "gmx",
            "GNO": "gnosis",
            "GNS": "gains-network",
            "GRT": "the-graph",
            "GTC": "gitcoin",
            "GYEN": "gyen",
            "HARD": "kava-lend",
            "HBAR": "hedera-hashgraph",
            "HFT": "hashflow",
            "HIFI": "hifi-finance",
            "HIGH": "highstreet",
            "HIVE": "hive",
            "HOOK": "hooked-protocol",
            "HOT": "holotoken",
            "ICP": "internet-computer",
            "ICX": "icon",
            "ID": "space-id",
            "IDEX": "aurora-dao",
            "IDRT": "rupiah-token",
            "ILV": "illuvium",
            "IMX": "immutable-x",
            "INJ": "injective-protocol",
            "IOST": "iostoken",
            "IOTX": "iotex",
            "IQ": "everipedia",
            "IRIS": "iris-network",
            "JASMY": "jasmycoin",
            "JOE": "joe",
            "JST": "just",
            "JUV": "juventus-fan-token",
            "KAVA": "kava",
            "KDA": "kadena",
            "KEY": "selfkey",
            "KEYFI": "keyfi",
            "KLAY": "klay-token",
            "KMD": "komodo",
            "KNC": "kyber-network-crystal",
            "KNCL": "kyber-network",
            "KP3R": "keep3rv1",
            "KSM": "kusama",
            "LAZIO": "lazio-fan-token",
            "LBA": "libra-credit",
            "LDO": "lido-dao",
            "LEVER": "lever",
            "LINA": "linear",
            "LINK": "chainlink",
            "LIT": "litentry",
            "LOKA": "league-of-kingdoms",
            "LOOKS": "looksrare",
            "LOOM": "loom-network-new",
            "LPT": "livepeer",
            "LQTY": "liquity",
            "LRC": "loopring",
            "LSK": "lisk",
            "LTC": "litecoin",
            "LTO": "lto-network",
            "LUNA": "terra-luna-2",
            "MAGIC": "magic",
            "MANA": "decentraland",
            "MASK": "mask-network",
            "MATIC": "matic-network",
            "MBL": "moviebloc",
            "MBOX": "mobox",
            "MC": "merit-circle",
            "MDT": "measurable-data-token",
            "MDX": "mdex",
            "MINA": "mina-protocol",
            "MKR": "maker",
            "MLN": "melon",
            "MOB": "mobilecoin",
            "MOVR": "moonriver",
            "MTL": "metal",
            "MTLX": "mettalex",
            "MULTI": "multichain",
            "NEAR": "near",
            "NEBL": "neblio",
            "NEO": "neo",
            "NEXO": "nexo",
            "NFT": "apenft",
            "NKN": "nkn",
            "NMR": "numeraire",
            "NULS": "nuls",
            "NVT": "nervenetwork",
            "OAX": "openanx",
            "OCEAN": "ocean-protocol",
            "OG": "og-fan-token",
            "OGN": "origin-protocol",
            "OM": "mantra-dao",
            "OMG": "omisego",
            "ONE": "harmony",
            "ONT": "ontology",
            "OOKI": "ooki",
            "OP": "optimism",
            "ORN": "orion-protocol",
            "OSMO": "osmosis",
            "OXT": "orchid-protocol",
            "PARA": "paralink-network",
            "PAXG": "pax-gold",
            "PEOPLE": "constitutiondao",
            "PEPE": "pepe",
            "PERL": "perlin",
            "PERP": "perpetual-protocol",
            "PHA": "pha",
            "PHB": "phoenix-global",
            "PIVX": "pivx",
            "PLA": "playdapp",
            "PNT": "pnetwork",
            "POLS": "polkastarter",
            "POLYX": "polymesh",
            "POND": "marlin",
            "PORTO": "fc-porto",
            "POWR": "power-ledger",
            "PROM": "prometeus",
            "PROS": "prosper",
            "PSG": "paris-saint-germain-fan-token",
            "PUNDIX": "pundi-x-2",
            "PYR": "vulcan-forged",
            "QI": "benqi",
            "QKC": "quark-chain",
            "QLC": "qlink",
            "QNT": "quant-network",
            "QTUM": "qtum",
            "QUICK": "quickswap",
            "RAD": "radicle",
            "RARE": "superrare",
            "RAY": "raydium",
            "RCN": "ripio-credit-network",
            "RDNT": "radiant-capital",
            "REEF": "reef",
            "REI": "rei-network",
            "REN": "republic-protocol",
            "REQ": "request-network",
            "RIF": "rif-token",
            "RLC": "iexec-rlc",
            "RNDR": "render-token",
            "ROSE": "oasis-network",
            "RPL": "rocket-pool",
            "RSR": "reserve-rights-token",
            "RUNE": "thorchain",
            "RVN": "ravencoin",
            "SAND": "the-sandbox",
            "SANTOS": "santos-fc-fan-token",
            "SC": "siacoin",
            "SCRT": "secret",
            "SFP": "safepal",
            "SHIB": "shiba-inu",
            "SKL": "skale",
            "SLP": "smooth-love-potion",
            "SNM": "sonm",
            "SNT": "status",
            "SNX": "havven",
            "SOL": "solana",
            "SOLO": "solo-coin",
            "SPELL": "spell-token",
            "SRM": "serum",
            "SSV": "ssv-network",
            "STEEM": "steem",
            "STG": "stargate-finance",
            "STMX": "storm",
            "STORJ": "storj",
            "STPT": "stp-network",
            "STRAX": "stratis",
            "STX": "blockstack",
            "SUI": "sui",
            "SUN": "sun-token",
            "SUPER": "superfarm",
            "SUSHI": "sushi",
            "SXP": "swipe",
            "SYN": "synapse-2",
            "SYS": "syscoin",
            "TCT": "tokenclub",
            "TFUEL": "theta-fuel",
            "THETA": "theta-token",
            "TKO": "tokocrypto",
            "TLM": "alien-worlds",
            "TOMO": "tomochain",
            "TORN": "tornado-cash",
            "TRB": "tellor",
            "TROY": "troy",
            "TRU": "truefi",
            "TRX": "tron",
            "TUSD": "true-usd",
            "TVK": "the-virtua-kolect",
            "TWT": "trust-wallet-token",
            "UFT": "unlend-finance",
            "UMA": "uma",
            "UNFI": "unifi-protocol-dao",
            "UNI": "uniswap",
            "USDC": "usd-coin",
            "USDP": "paxos-standard",
            "USDT": "tether",
            "UTK": "utrust",
            "VAI": "vai",
            "VET": "vechain",
            "VGX": "ethos",
            "VIB": "viberate",
            "VIDT": "vidt-dao",
            "VITE": "vite",
            "VOXEL": "voxies",
            "VRT": "venus-reward-token",
            "VTHO": "vethor-token",
            "WAN": "wanchain",
            "WAVES": "waves",
            "WAXP": "wax",
            "WBNB": "wbnb",
            "WBTC": "wrapped-bitcoin",
            "WETH": "weth",
            "WIN": "wink",
            "WING": "wing-finance",
            "WNXM": "wrapped-nxm",
            "WOO": "woo-network",
            "WRX": "wazirx",
            "WTC": "waltonchain",
            "XEC": "ecash",
            "XEM": "nem",
            "XLM": "stellar",
            "XMR": "monero",
            "XNO": "nano",
            "XRP": "ripple",
            "XTZ": "tezos",
            "XVG": "verge",
            "XVS": "venus",
            "YFI": "yearn-finance",
            "YFII": "yfii-finance",
            "YGG": "yield-guild-games",
            "ZEC": "zcash",
            "ZEN": "zencash",
            "ZIL": "zilliqa",
            "ZRX": "0x",
        ]
    }

    private func blockchainUidMap() async throws -> [String: String] {
        [
            "BTC": "bitcoin",
            "BSC": "binance-smart-chain",
            "ETH": "ethereum",
            "EOS": "eos",
            "NEAR": "near-protocol",
            "AVAXC": "avalanche",
            "ARBITRUM": "arbitrum-one",
            "BNB": "binancecoin",
            "OPTIMISM": "optimistic-ethereum",
            "MATIC": "polygon-pos",
            "STATEMINT": "polkadot",
            "SOL": "solana",
            "XTZ": "tezos",
            "TRX": "tron",
            "APT": "aptos",
            "ADA": "cardano",
            "FTM": "fantom",
            "BCH": "bitcoin-cash",
            "ETC": "ethereum-classic",
            "FIL": "filecoin",
            "FLOW": "flow",
            "LTC": "litecoin",
            "XRP": "ripple",
            "ZEC": "zcash",
        ]
    }

    private static func signed(parameters: Parameters, apiKey: String, secret: String) throws -> (Parameters, HTTPHeaders) {
        var parameters = parameters

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        parameters["timestamp"] = timestamp

        let queryString = parameters.map { ($0, $1) }.sorted { $0.0 < $1.0 }.map { "\($0)=\($1)" }.joined(separator: "&")

        guard let queryStringData = queryString.data(using: .utf8) else {
            throw RequestError.invalidQueryString
        }

        guard let secretData = secret.data(using: .utf8) else {
            throw RequestError.invalidSecret
        }

        let symmetricKey = SymmetricKey(data: secretData)
        let signature = Data(HMAC<SHA256>.authenticationCode(for: queryStringData, using: symmetricKey))
        parameters["signature"] = Data(signature).hs.hex

        return (parameters, HTTPHeaders(["X-MBX-APIKEY": apiKey]))
    }

    private static func fetch<T: ImmutableMappable>(networkManager: NetworkManager, apiKey: String, secret: String, path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> T {
        let (parameters, headers) = try signed(parameters: parameters, apiKey: apiKey, secret: secret)
        return try await networkManager.fetch(url: baseUrl + path, method: method, parameters: parameters, headers: headers)
    }

    private static func fetch<T: ImmutableMappable>(networkManager: NetworkManager, apiKey: String, secret: String, path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> [T] {
        let (parameters, headers) = try signed(parameters: parameters, apiKey: apiKey, secret: secret)
        return try await networkManager.fetch(url: baseUrl + path, method: method, parameters: parameters, headers: headers)
    }

    private func fetch<T: ImmutableMappable>(path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> T {
        try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: path, method: method, parameters: parameters)
    }

    private func fetch<T: ImmutableMappable>(path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> [T] {
        try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: path, method: method, parameters: parameters)
    }

}

extension BinanceCexProvider: ICexAssetProvider {

    func assets() async throws -> [CexAssetResponse] {
        let response: [AssetResponse] = try await fetch(path: "/sapi/v1/capital/config/getall")

        let coinUidMap = try await coinUidMap()
        let blockchainUidMap = try await blockchainUidMap()

        return response
                .filter { asset in
                    !asset.isLegalMoney
                }
                .map { asset in
                    CexAssetResponse(
                            id: asset.coin,
                            name: asset.name,
                            freeBalance: asset.free,
                            lockedBalance: asset.locked,
                            depositEnabled: asset.depositAllEnable,
                            withdrawEnabled: false,
                            depositNetworks: asset.networks.map { network in
                                CexDepositNetworkRaw(
                                        id: network.network,
                                        name: network.name,
                                        isDefault: network.isDefault,
                                        enabled: network.depositEnable,
                                        minAmount: 0,
                                        blockchainUid: blockchainUidMap[network.network]
                                )
                            },
                            withdrawNetworks: asset.networks.map { network in
                                CexWithdrawNetworkRaw(
                                        id: network.network,
                                        name: network.name,
                                        isDefault: network.isDefault,
                                        enabled: network.withdrawEnable,
                                        minAmount: network.withdrawMin,
                                        maxAmount: network.withdrawMax,
                                        fixedFee: network.withdrawFee,
                                        feePercent: 0,
                                        minFee: 0,
                                        blockchainUid: blockchainUidMap[network.network]
                                )
                            },
                            coinUid: coinUidMap[asset.coin]
                    )
                }
    }

}

extension BinanceCexProvider: ICexDepositProvider {

    func deposit(id: String, network: String?) async throws -> (String, String?) {
        var parameters: Parameters = [
            "coin": id
        ]

        if let network {
            parameters["network"] = network
        }

        let response: DepositResponse = try await fetch(path: "/sapi/v1/capital/deposit/address", parameters: parameters)
        return (response.address, response.tag.isEmpty ? nil : response.tag)
    }

}

extension BinanceCexProvider {

    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> String {
        var parameters: Parameters = [
            "coin": id,
            "address": address,
            "amount": amount
        ]

        if let network {
            parameters["network"] = network
        }

        let response: WithdrawResponse = try await fetch(path: "/sapi/v1/capital/withdraw/apply", method: .post, parameters: parameters)
        return response.id
    }

}

extension BinanceCexProvider {

    static func validate(apiKey: String, secret: String, networkManager: NetworkManager) async throws {
        let _: [AssetResponse] = try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: "/sapi/v1/capital/config/getall")
    }

}

extension BinanceCexProvider {

    private struct AssetResponse: ImmutableMappable {
        let coin: String
        let name: String
        let free: Decimal
        let locked: Decimal
        let depositAllEnable: Bool
        let withdrawAllEnable: Bool
        let isLegalMoney: Bool
        let networks: [Network]

        init(map: Map) throws {
            coin = try map.value("coin")
            name = try map.value("name")
            free = try map.value("free", using: Transform.stringToDecimalTransform)
            locked = try map.value("locked", using: Transform.stringToDecimalTransform)
            depositAllEnable = try map.value("depositAllEnable")
            withdrawAllEnable = try map.value("withdrawAllEnable")
            isLegalMoney = try map.value("isLegalMoney")
            networks = try map.value("networkList")
        }

        struct Network: ImmutableMappable {
            let network: String
            let name: String
            let isDefault: Bool
            let depositEnable: Bool
            let withdrawEnable: Bool
            let withdrawFee: Decimal
            let withdrawMin: Decimal
            let withdrawMax: Decimal

            init(map: Map) throws {
                network = try map.value("network")
                name = try map.value("name")
                isDefault = try map.value("isDefault")
                depositEnable = try map.value("depositEnable")
                withdrawEnable = try map.value("withdrawEnable")
                withdrawFee = try map.value("withdrawFee", using: Transform.stringToDecimalTransform)
                withdrawMax = try map.value("withdrawMax", using: Transform.stringToDecimalTransform)
                withdrawMin = try map.value("withdrawMin", using: Transform.stringToDecimalTransform)
            }
        }
    }

    private struct DepositResponse: ImmutableMappable {
        let address: String
        let tag: String

        init(map: Map) throws {
            address = try map.value("address")
            tag = try map.value("tag")
        }
    }

    private struct WithdrawResponse: ImmutableMappable {
        let id: String

        init(map: Map) throws {
            id = try map.value("id")
        }
    }

    enum RequestError: Error {
        case invalidSecret
        case invalidQueryString
    }

}
