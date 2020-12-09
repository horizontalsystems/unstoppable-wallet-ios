import Foundation

class AppConfigProvider: IAppConfigProvider {
    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://unstoppable.money"
    let appGitHubLink = "https://github.com/horizontalsystems/unstoppable-wallet-ios"
    let reportEmail = "support.unstoppable@protonmail.com"
    let telegramAccount = "unstoppable_announcements"
    let twitterAccount = "UnstoppableByHS"
    let redditAccount = "UNSTOPPABLEWallet"

    var guidesIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "GuidesIndexUrl") as! String))!
    }

    var faqIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "FaqIndexUrl") as! String))!
    }

    var uniswapSubgraphUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "UniswapGraphUrl") as? String) ?? ""
    }

    var testMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
    }

    var sandbox: Bool {
        Bundle.main.object(forInfoDictionaryKey: "Sandbox") as? String == "true"
    }

    func defaultWords(count: Int) -> String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords\(count)") as? String ?? ""
    }

    var defaultEosCredentials: (String, String) {
        guard let account = Bundle.main.object(forInfoDictionaryKey: "DefaultEosAccount") as? String, let privateKey = Bundle.main.object(forInfoDictionaryKey: "DefaultEosPrivateKey") as? String else {
            return ("", "")
        }

        return (account, privateKey)
    }

    var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var btcCoreRpcUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "BtcCoreRpcUrl") as? String) ?? ""
    }

    var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var coinMarketCapApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "CoinMarketCapKey") as? String) ?? ""
    }

    var cryptoCompareApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "CryptoCompareApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    var pnsUrl: String {
        let development = "https://pns-dev.horizontalsystems.xyz/api/v1/"
        let production = "https://pns.horizontalsystems.xyz/api/v1/"

        return sandbox ? development : production
    }

    var pnsUsername: String {
        (Bundle.main.object(forInfoDictionaryKey: "PnsUsername") as? String) ?? ""
    }

    var pnsPassword: String {
        (Bundle.main.object(forInfoDictionaryKey: "PnsPassword") as? String) ?? ""
    }

    let currencyCodes: [String] = ["USD", "EUR", "GBP", "JPY"]

    private static let ethereumCoin = Coin(id: "ETH", title: "Ethereum", code: "ETH", decimal: 18, type: .ethereum)

    var ethereumCoin: Coin {
        Self.ethereumCoin
    }

    var featuredCoins: [Coin] {
        [
            defaultCoins[0],
            defaultCoins[1],
            defaultCoins[2],
            defaultCoins[3],
            defaultCoins[4],
            defaultCoins[5],
            defaultCoins[6],
            defaultCoins[7],
        ]
    }

    var defaultCoins: [Coin] {
        testMode ? testNetCoins : mainNetCoins
    }

    private let mainNetCoins = [
        Coin(id: "BTC",       title: "Bitcoin",                       code: "BTC",     decimal: 8,  type: .bitcoin),
        Coin(id: "LTC",       title: "Litecoin",                      code: "LTC",     decimal: 8,  type: .litecoin),
        ethereumCoin,
        Coin(id: "BCH",       title: "Bitcoin Cash",                  code: "BCH",     decimal: 8,  type: .bitcoinCash),
        Coin(id: "DASH",      title: "Dash",                          code: "DASH",    decimal: 8,  type: .dash),
        Coin(id: "BNB",       title: "Binance Chain",                 code: "BNB",     decimal: 8,  type: .binance(symbol: "BNB")),
        Coin(id: "ZEC",       title: "Zcash",                         code: "ZEC",     decimal: 8,  type: .zcash),
        Coin(id: "EOS",       title: "EOS",                           code: "EOS",     decimal: 4,  type: .eos(token: "eosio.token", symbol: "EOS")),
        Coin(id: "ZRX",       title: "0x Protocol",                   code: "ZRX",     decimal: 18, type: CoinType(erc20Address: "0xE41d2489571d322189246DaFA5ebDe1F4699F498")),
        Coin(id: "LEND",      title: "Aave",                          code: "LEND",    decimal: 18, type: CoinType(erc20Address: "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03")),
        Coin(id: "AAVE",      title: "Aave Token",                    code: "AAVE",    decimal: 18, type: CoinType(erc20Address: "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9")),
        Coin(id: "AAVEDAI",   title: "Aave DAI",                      code: "ADAI",    decimal: 18, type: CoinType(erc20Address: "0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d")),
        Coin(id: "ELF",       title: "Aelf",                          code: "ELF",     decimal: 18, type: CoinType(erc20Address: "0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e")),
        Coin(id: "AST",       title: "AirSwap",                       code: "AST",     decimal: 4,  type: CoinType(erc20Address: "0x27054b13b1b798b345b591a4d22e6562d47ea75a")),
        Coin(id: "AKRO",      title: "Akropolis",                     code: "AKRO",    decimal: 18, type: CoinType(erc20Address: "0x8ab7404063ec4dbcfd4598215992dc3f8ec853d7")),
        Coin(id: "AMON",      title: "Amon",                          code: "AMN",     decimal: 18, type: CoinType(erc20Address: "0x737f98ac8ca59f2c68ad658e3c3d8c8963e40a4c")),
        Coin(id: "AMPL",      title: "Ampleforth",                    code: "AMPL",    decimal: 9,  type: CoinType(erc20Address: "0xd46ba6d942050d489dbd938a2c909a5d5039a161")),
        Coin(id: "ANKR",      title: "Ankr Network",                  code: "ANKR",    decimal: 8,  type: .binance(symbol: "ANKR-E97")),
        Coin(id: "ANT",       title: "Aragon",                        code: "ANT",     decimal: 18, type: CoinType(erc20Address: "0x960b236A07cf122663c4303350609A66A7B288C0")),
        Coin(id: "ANJ",       title: "Aragon Network Juror",          code: "ANJ",     decimal: 18, type: CoinType(erc20Address: "0xcD62b1C403fa761BAadFC74C525ce2B51780b184")),
        Coin(id: "REP",       title: "Augur",                         code: "REP",     decimal: 18, type: CoinType(erc20Address: "0x1985365e9f78359a9B6AD760e32412f4a445E862")),
        Coin(id: "BAL",       title: "Balancer",                      code: "BAL",     decimal: 18, type: CoinType(erc20Address: "0xba100000625a3754423978a60c9317c58a424e3D")),
        Coin(id: "BNT",       title: "Bancor",                        code: "BNT",     decimal: 18, type: CoinType(erc20Address: "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C")),
        Coin(id: "BAND",      title: "BandToken",                     code: "BAND",    decimal: 18, type: CoinType(erc20Address: "0xba11d00c5f74255f56a5e366f4f77f5a186d7f55")),
        Coin(id: "BAT",       title: "Basic Attention Token",         code: "BAT",     decimal: 18, type: CoinType(erc20Address: "0x0D8775F648430679A709E98d2b0Cb6250d2887EF")),
        Coin(id: "TRYB",      title: "BiLira",                        code: "TRYB",    decimal: 6,  type: CoinType(erc20Address: "0x2c537e5624e4af88a7ae4060c022609376c8d0eb")),
        Coin(id: "BNB-ERC20", title: "Binance ERC20",                 code: "BNB",     decimal: 18, type: CoinType(erc20Address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")),
        Coin(id: "BUSD",      title: "Binance USD",                   code: "BUSD",    decimal: 8,  type: .binance(symbol: "BUSD-BD1")),
        Coin(id: "BTCB",      title: "Bitcoin BEP2",                  code: "BTCB",    decimal: 8,  type: .binance(symbol: "BTCB-1DE")),
        Coin(id: "BLT",       title: "Bloom",                         code: "BLT",     decimal: 18, type: CoinType(erc20Address: "0x107c4504cd79c5d2696ea0030a8dd4e92601b82e")),
        Coin(id: "BZRX",      title: "bZx Protocol Token",            code: "BZRX",    decimal: 18, type: CoinType(erc20Address: "0x56d811088235F11C8920698a204A5010a788f4b3")),
        Coin(id: "CAS",       title: "Cashaa",                        code: "CAS",     decimal: 8,  type: .binance(symbol: "CAS-167")),
        Coin(id: "CELR",      title: "CelerToken",                    code: "CELR",    decimal: 18, type: CoinType(erc20Address: "0x4f9254c83eb525f9fcf346490bbb3ed28a81c667")),
        Coin(id: "CEL",       title: "Celsius",                       code: "CEL",     decimal: 4,  type: CoinType(erc20Address: "0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d")),
        Coin(id: "LINK",      title: "Chainlink",                     code: "LINK",    decimal: 18, type: CoinType(erc20Address: "0x514910771AF9Ca656af840dff83E8264EcF986CA")),
        Coin(id: "CHZ",       title: "Chiliz",                        code: "CHZ",     decimal: 8,  type: .binance(symbol: "CHZ-ECD")),
        Coin(id: "CVC",       title: "Civic",                         code: "CVC",     decimal: 8,  type: CoinType(erc20Address: "0x41e5560054824ea6b0732e656e3ad64e20e94e45")),
        Coin(id: "COMP",      title: "Compound",                      code: "COMP",    decimal: 18, type: CoinType(erc20Address: "0xc00e94cb662c3520282e6f5717214004a7f26888")),
        Coin(id: "CDAI",      title: "Compound Dai",                  code: "CDAI",    decimal: 8,  type: CoinType(erc20Address: "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643")),
        Coin(id: "CSAI",      title: "Compound Sai",                  code: "CSAI",    decimal: 8,  type: CoinType(erc20Address: "0xf5dce57282a584d2746faf1593d3121fcac444dc")),
        Coin(id: "CUSDC",     title: "Compound USDC",                 code: "CUSDC",   decimal: 8,  type: CoinType(erc20Address: "0x39aa39c021dfbae8fac545936693ac917d5e7563")),
        Coin(id: "COS",       title: "Contentos",                     code: "COS",     decimal: 8,  type: .binance(symbol: "COS-2E4")),
        Coin(id: "CRPT",      title: "Crypterium",                    code: "CRPT",    decimal: 8,  type: .binance(symbol: "CRPT-8C9")),
        Coin(id: "CRO",       title: "Crypto.com Coin",               code: "CRO",     decimal: 8,  type: CoinType(erc20Address: "0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b")),
        Coin(id: "CRV",       title: "Curve DAO Token",               code: "CRV",     decimal: 18, type: CoinType(erc20Address: "0xD533a949740bb3306d119CC777fa900bA034cd52")),
        Coin(id: "DAI",       title: "Dai",                           code: "DAI",     decimal: 18, type: CoinType(erc20Address: "0x6b175474e89094c44da98b954eedeac495271d0f")),
        Coin(id: "RING",      title: "Darwinia Network Native Token", code: "RING",    decimal: 18, type: CoinType(erc20Address: "0x9469d013805bffb7d3debe5e7839237e535ec483")),
        Coin(id: "GEN",       title: "DAOstack",                      code: "GEN",     decimal: 18, type: CoinType(erc20Address: "0x543ff227f64aa17ea132bf9886cab5db55dcaddf")),
        Coin(id: "DATA",      title: "DATACoin",                      code: "DATA",    decimal: 18, type: CoinType(erc20Address: "0x0cf0ee63788a0849fe5297f3407f701e122cc023")),
        Coin(id: "MANA",      title: "Decentraland",                  code: "MANA",    decimal: 18, type: CoinType(erc20Address: "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942")),
        Coin(id: "DEFI",      title: "DeFi Token",                    code: "DEFI",    decimal: 8,  type: .binance(symbol: "DEFI-FA5")),
        Coin(id: "DIA",       title: "DIA",                           code: "DIA",     decimal: 18, type: CoinType(erc20Address: "0x84ca8bc7997272c7cfb4d0cd3d55cd942b3c9419")),
        Coin(id: "DGD",       title: "DigixDAO",                      code: "DGD",     decimal: 9,  type: CoinType(erc20Address: "0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A")),
        Coin(id: "DGX",       title: "Digix Gold Token",              code: "DGX",     decimal: 9,  type: CoinType(erc20Address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF", minimumSpendableAmount: 0.001)),
        Coin(id: "DNT",       title: "District0x",                    code: "DNT",     decimal: 18, type: CoinType(erc20Address: "0x0abdace70d3790235af448c88547603b945604ea")),
        Coin(id: "DONUT",     title: "Donut",                         code: "DONUT",   decimal: 18, type: CoinType(erc20Address: "0xc0f9bd5fa5698b6505f643900ffa515ea5df54a9")),
        Coin(id: "DOS",       title: "DOS Network",                   code: "DOS",     decimal: 8,  type: .binance(symbol: "DOS-120")),
        Coin(id: "DOS-ERC20", title: "DOS Network",                   code: "DOS",     decimal: 18, type: CoinType(erc20Address: "0x0A913beaD80F321E7Ac35285Ee10d9d922659cB7")),
        Coin(id: "ENJ",       title: "Enjin Coin",                    code: "ENJ",     decimal: 18, type: CoinType(erc20Address: "0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c")),
        Coin(id: "EOSDT",     title: "EOSDT",                         code: "EOSDT",   decimal: 9,  type: .eos(token: "eosdtsttoken", symbol: "EOSDT")),
        Coin(id: "ETH-BEP2",  title: "ETH BEP2",                      code: "ETH",     decimal: 8,  type: .binance(symbol: "ETH-1C9")),
        Coin(id: "DIP",       title: "Etherisc",                      code: "DIP",     decimal: 18, type: CoinType(erc20Address: "0xc719d010b63e5bbf2c0551872cd5316ed26acd83")),
        Coin(id: "IQ",        title: "Everipedia",                    code: "IQ",      decimal: 3,  type: .eos(token: "everipediaiq", symbol: "IQ")),
        Coin(id: "EBASE",     title: "EURBASE Stablecoin V2",         code: "EBASE",   decimal: 18, type: CoinType(erc20Address: "0xa689dcea8f7ad59fb213be4bc624ba5500458dc6")),
        Coin(id: "FXC",       title: "Flexacoin",                     code: "FXC",     decimal: 18, type: CoinType(erc20Address: "0x4a57e687b9126435a9b19e4a802113e266adebde")),
        Coin(id: "FOAM",      title: "FOAM Token",                    code: "FOAM",    decimal: 18, type: CoinType(erc20Address: "0x4946fcea7c692606e8908002e55a582af44ac121")),
        Coin(id: "FUN",       title: "FunFair",                       code: "FUN",     decimal: 8,  type: CoinType(erc20Address: "0x419d0d8bdd9af5e606ae2232ed285aff190e711b")),
        Coin(id: "GST2",      title: "Gas Token Two",                 code: "GST2",    decimal: 2,  type: CoinType(erc20Address: "0x0000000000b3f879cb30fe243b4dfee438691c04")),
        Coin(id: "GUSD",      title: "Gemini Dollar",                 code: "GUSD",    decimal: 2,  type: CoinType(erc20Address: "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd")),
        Coin(id: "GTO",       title: "Gifto",                         code: "GTO",     decimal: 8,  type: .binance(symbol: "GTO-908")),
        Coin(id: "GNO",       title: "Gnosis",                        code: "DATA",    decimal: 18, type: CoinType(erc20Address: "0x6810e776880c02933d47db1b9fc05908e5386b96")),
        Coin(id: "GNT",       title: "Golem",                         code: "GNT",     decimal: 18, type: CoinType(erc20Address: "0xa74476443119A942dE498590Fe1f2454d7D4aC0d")),
        Coin(id: "GRID",      title: "Grid",                          code: "GRID",    decimal: 12, type: CoinType(erc20Address: "0x12b19d3e2ccc14da04fae33e63652ce469b3f2fd")),
        Coin(id: "XCHF",      title: "GryptoFranc",                   code: "XCHF",    decimal: 18, type: CoinType(erc20Address: "0xb4272071ecadd69d933adcd19ca99fe80664fc08")),
        Coin(id: "ONE",       title: "Harmony.One",                   code: "ONE",     decimal: 8,  type: .binance(symbol: "ONE-5F9")),
        Coin(id: "HEDG",      title: "HEDG",                          code: "HEDG",    decimal: 18, type: CoinType(erc20Address: "0xf1290473e210b2108a85237fbcd7b6eb42cc654f")),
        Coin(id: "HOT",       title: "Holo",                          code: "HOT",     decimal: 18, type: CoinType(erc20Address: "0x6c6EE5e31d828De241282B9606C8e98Ea48526E2")),
        Coin(id: "HT",        title: "Huobi Token",                   code: "HT",      decimal: 18, type: CoinType(erc20Address: "0x6f259637dcD74C767781E37Bc6133cd6A68aa161")),
        Coin(id: "HUSD",      title: "HUSD",                          code: "HUSD",    decimal: 8,  type: CoinType(erc20Address: "0xdf574c24545e5ffecb9a659c229253d4111d87e1")),
        Coin(id: "HYN",       title: "Hyperion Token",                code: "HYN",     decimal: 8,  type: .binance(symbol: "HYN-F21")),
        Coin(id: "IDXM",      title: "IDEX Membership",               code: "IDXM",    decimal: 8,  type: CoinType(erc20Address: "0xCc13Fc627EFfd6E35D2D2706Ea3C4D7396c610ea")),
        Coin(id: "IDEX",      title: "IDEX",                          code: "IDEX",    decimal: 18, type: CoinType(erc20Address: "0xB705268213D593B8FD88d3FDEFF93AFF5CbDcfAE")),
        Coin(id: "IOTX",      title: "IoTeX",                         code: "IOTX",    decimal: 18, type: CoinType(erc20Address: "0x6fb3e0a217407efff7ca062d46c26e5d60a14d69")),
        Coin(id: "IRIS",      title: "IRIS Network",                  code: "IRIS",    decimal: 8,  type: .binance(symbol: "IRIS-D88")),
        Coin(id: "KCS",       title: "KuCoin Shares",                 code: "KCS",     decimal: 6,  type: CoinType(erc20Address: "0x039B5649A59967e3e936D7471f9c3700100Ee1ab", minimumRequiredBalance: 0.001)),
        Coin(id: "KNC",       title: "Kyber Network Crystal",         code: "KNC",     decimal: 18, type: CoinType(erc20Address: "0xdd974D5C2e2928deA5F71b9825b8b646686BD200")),
        Coin(id: "LPT",       title: "Livepeer Token",                code: "LPT",     decimal: 18, type: CoinType(erc20Address: "0x58b6a8a3302369daec383334672404ee733ab239")),
        Coin(id: "LQD",       title: "Liquidity Network",             code: "LQD",     decimal: 18, type: CoinType(erc20Address: "0xd29f0b5b3f50b07fe9a9511f7d86f4f4bac3f8c4")),
        Coin(id: "LOOM",      title: "Loom Network",                  code: "LOOM",    decimal: 18, type: CoinType(erc20Address: "0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0")),
        Coin(id: "LRC",       title: "Loopring",                      code: "LRC",     decimal: 18, type: CoinType(erc20Address: "0xEF68e7C694F40c8202821eDF525dE3782458639f")),
        Coin(id: "LTO",       title: "LTO Network",                   code: "LTO",     decimal: 8,  type: .binance(symbol: "LTO-BDF")),
        Coin(id: "MCX",       title: "MachiX Token",                  code: "MCX",     decimal: 18, type: CoinType(erc20Address: "0xd15ecdcf5ea68e3995b2d0527a0ae0a3258302f8")),
        Coin(id: "MBC",       title: "Marblecoin",                    code: "MBC",     decimal: 18, type: CoinType(erc20Address: "0x8888889213dd4da823ebdd1e235b09590633c150")),
        Coin(id: "MATIC",     title: "Matic Token",                   code: "MATIC",   decimal: 18, type: CoinType(erc20Address: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0")),
        Coin(id: "MATIC-BEP2",title: "Matic Token",                   code: "MATIC",   decimal: 8,  type: .binance(symbol: "MATIC-84A")),
        Coin(id: "MKR",       title: "Maker",                         code: "MKR",     decimal: 18, type: CoinType(erc20Address: "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2")),
        Coin(id: "MLN",       title: "Melon Token",                   code: "MLN",     decimal: 18, type: CoinType(erc20Address: "0xec67005c4e498ec7f55e092bd1d35cbc47c91892")),
        Coin(id: "MET",       title: "Metronome",                     code: "MET",     decimal: 18, type: CoinType(erc20Address: "0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e")),
        Coin(id: "MCO",       title: "MCO",                           code: "MCO",     decimal: 8,  type: CoinType(erc20Address: "0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d")),
        Coin(id: "MEETONE",   title: "MEET.ONE",                      code: "MEETONE", decimal: 4,  type: .eos(token: "eosiomeetone", symbol: "MEETONE")),
        Coin(id: "MTA",       title: "Meta",                          code: "MTA",     decimal: 18, type: CoinType(erc20Address: "0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2")),
        Coin(id: "MITH",      title: "Mithril",                       code: "MITH",    decimal: 18, type: CoinType(erc20Address: "0x3893b9422Cd5D70a81eDeFfe3d5A1c6A978310BB")),
        Coin(id: "MOD",       title: "Modum Token",                   code: "MOD",     decimal: 0,  type: CoinType(erc20Address: "0x957c30ab0426e0c93cd8241e2c60392d08c6ac8e")),
        Coin(id: "MUSD",      title: "mStable USD",                   code: "MUSD",    decimal: 18, type: CoinType(erc20Address: "0xe2f2a5c287993345a840db3b0845fbc70f5935a5")),
        Coin(id: "TKN",       title: "Monolith",                      code: "TKN",     decimal: 8,  type: CoinType(erc20Address: "0xaaaf91d9b90df800df4f55c205fd6989c977e73a")),
        Coin(id: "NUT",       title: "Native Utility Token",          code: "NUT",     decimal: 9,  type: .eos(token: "eosdtnutoken", symbol: "NUT")),
        Coin(id: "NDX",       title: "Newdex",                        code: "NDX",     decimal: 4,  type: .eos(token: "newdexissuer", symbol: "NDX")),
        Coin(id: "NEXO",      title: "Nexo",                          code: "NEXO",    decimal: 18, type: CoinType(erc20Address: "0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206")),
        Coin(id: "NMR",       title: "Numeraire",                     code: "NMR",     decimal: 18, type: CoinType(erc20Address: "0x1776e1f26f98b1a5df9cd347953a26dd3cb46671")),
        Coin(id: "OCEAN",     title: "Ocean Token",                   code: "OCEAN",   decimal: 18, type: CoinType(erc20Address: "0x967da4048cD07aB37855c090aAF366e4ce1b9F48")),
        Coin(id: "XFT",       title: "Offshift",                      code: "XFT",     decimal: 18, type: CoinType(erc20Address: "0xabe580e7ee158da464b51ee1a83ac0289622e6be")),
        Coin(id: "OMG",       title: "OmiseGO",                       code: "OMG",     decimal: 18, type: CoinType(erc20Address: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07")),
        Coin(id: "ORBS",      title: "Orbs",                          code: "ORBS",    decimal: 18, type: CoinType(erc20Address: "0xff56Cc6b1E6dEd347aA0B7676C85AB0B3D08B0FA")),
        Coin(id: "OXT",       title: "Orchid",                        code: "OXT",     decimal: 18, type: CoinType(erc20Address: "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb")),
        Coin(id: "PAR",       title: "Parachute",                     code: "PAR",     decimal: 18, type: CoinType(erc20Address: "0x1beef31946fbbb40b877a72e4ae04a8d1a5cee06")),
        Coin(id: "PAX",       title: "Paxos Standard",                code: "PAX",     decimal: 18, type: CoinType(erc20Address: "0x8E870D67F660D95d5be530380D0eC0bd388289E1")),
        Coin(id: "PAXG",      title: "PAX Gold",                      code: "PAXG",    decimal: 18, type: CoinType(erc20Address: "0x45804880De22913dAFE09f4980848ECE6EcbAf78")),
        Coin(id: "PTI",       title: "Paytomat",                      code: "PTI",     decimal: 4,  type: .eos(token: "ptitokenhome", symbol: "PTI")),
        Coin(id: "PNK",       title: "Pinakion",                      code: "PNK",     decimal: 18, type: CoinType(erc20Address: "0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d")),
        Coin(id: "POA",       title: "POA ERC20 on Foundation",       code: "POA",     decimal: 18, type: CoinType(erc20Address: "0x6758b7d441a9739b98552b373703d8d3d14f9e62")),
        Coin(id: "POLY",      title: "Polymath",                      code: "POLY",    decimal: 18, type: CoinType(erc20Address: "0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC")),
        Coin(id: "PPT",       title: "Populous",                      code: "PPT",     decimal: 8,  type: CoinType(erc20Address: "0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a")),
        Coin(id: "PGL",       title: "Prospectors Gold",              code: "PGL",     decimal: 4,  type: .eos(token: "prospectorsg", symbol: "PGL")),
        Coin(id: "NPXS",      title: "Pundi X",                       code: "NPXS",    decimal: 18, type: CoinType(erc20Address: "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3")),
        Coin(id: "QCH",       title: "QChi",                          code: "QCH",     decimal: 18, type: CoinType(erc20Address: "0x687bfc3e73f6af55f0ccca8450114d107e781a0e")),
        Coin(id: "QNT",       title: "Quant",                         code: "QNT",     decimal: 18, type: CoinType(erc20Address: "0x4a220e6096b25eadb88358cb44068a3248254675")),
        Coin(id: "QSP",       title: "Quantstamp",                    code: "QSP",     decimal: 18, type: CoinType(erc20Address: "0x99ea4db9ee77acd40b119bd1dc4e33e1c070b80d")),
        Coin(id: "RDN",       title: "Raiden",                        code: "RDN",     decimal: 18, type: CoinType(erc20Address: "0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6")),
        Coin(id: "REN",       title: "Ren",                           code: "REN",     decimal: 18, type: CoinType(erc20Address: "0x408e41876cccdc0f92210600ef50372656052a38")),
        Coin(id: "RENBTC",    title: "renBTC",                        code: "renBTC",  decimal: 8,  type: CoinType(erc20Address: "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d")),
        Coin(id: "RENBCH",    title: "renBCH",                        code: "renBCH",  decimal: 8,  type: CoinType(erc20Address: "0x459086f2376525bdceba5bdda135e4e9d3fef5bf")),
        Coin(id: "RENZEC",    title: "renZEC",                        code: "renZEC",  decimal: 8,  type: CoinType(erc20Address: "0x1c5db575e2ff833e46a2e9864c22f4b22e0b37c2")),
        Coin(id: "RARI",      title: "Rarible",                       code: "RARI",    decimal: 18, type: CoinType(erc20Address: "0xfca59cd816ab1ead66534d82bc21e7515ce441cf")),
        Coin(id: "REPv2",     title: "Reputation",                    code: "REPv2",   decimal: 8,  type: CoinType(erc20Address: "0x221657776846890989a759ba2973e427dff5c9bb")),
        Coin(id: "R",         title: "Revain",                        code: "R",       decimal: 0,  type: CoinType(erc20Address: "0x48f775EFBE4F5EcE6e0DF2f7b5932dF56823B990")),
        Coin(id: "RCN",       title: "RipioCreditNetwork",            code: "RCN",     decimal: 18, type: CoinType(erc20Address: "0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6")),
        Coin(id: "XRP",       title: "Ripple",                        code: "XRP",     decimal: 8,  type: .binance(symbol: "XRP-BF2")),
        Coin(id: "RLC",       title: "RLC",                           code: "RLC",     decimal: 9,  type: CoinType(erc20Address: "0x607F4C5BB672230e8672085532f7e901544a7375")),
        Coin(id: "RPL",       title: "Rocket Pool",                   code: "RPL",     decimal: 18, type: CoinType(erc20Address: "0xb4efd85c19999d84251304bda99e90b92300bd93")),
        Coin(id: "RUNE",      title: "Rune",                          code: "RUNE",    decimal: 8,  type: .binance(symbol: "RUNE-B1A")),
        Coin(id: "SAI",       title: "Sai",                           code: "SAI",     decimal: 18, type: CoinType(erc20Address: "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359")),
        Coin(id: "SALT",      title: "Salt",                          code: "SALT",    decimal: 8,  type: CoinType(erc20Address: "0x4156D3342D5c385a87D264F90653733592000581")),
        Coin(id: "SAN",       title: "SAN",                           code: "SAN",     decimal: 18, type: CoinType(erc20Address: "0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098")),
        Coin(id: "KEY",       title: "SelfKey",                       code: "KEY",     decimal: 18, type: CoinType(erc20Address: "0x4cc19356f2d37338b9802aa8e8fc58b0373296e7")),
        Coin(id: "SRM",       title: "Serum",                         code: "SRM",     decimal: 6,  type: CoinType(erc20Address: "0x476c5E26a75bd202a9683ffD34359C0CC15be0fF")),
        Coin(id: "SHR",       title: "ShareToken",                    code: "SHR",     decimal: 8,  type: .binance(symbol: "SHR-DB6")),
        Coin(id: "SHUF",      title: "Shuffle.Monster V3",            code: "SHUF",    decimal: 18, type: CoinType(erc20Address: "0x3a9fff453d50d4ac52a6890647b823379ba36b9e")),
        Coin(id: "SNX",       title: "Synthetix",                     code: "SNX",     decimal: 18, type: CoinType(erc20Address: "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F")),
        Coin(id: "SPANK",     title: "SPANK",                         code: "SPANK",   decimal: 18, type: CoinType(erc20Address: "0x42d6622dece394b54999fbd73d108123806f6a18")),
        Coin(id: "USDS",      title: "StableUSD",                     code: "USDS",    decimal: 6,  type: CoinType(erc20Address: "0xa4bdb11dc0a2bec88d24a3aa1e6bb17201112ebe")),
        Coin(id: "STAKE",     title: "STAKE",                         code: "STAKE",   decimal: 18, type: CoinType(erc20Address: "0x0Ae055097C6d159879521C384F1D2123D1f195e6")),
        Coin(id: "EURS",      title: "STASIS EURO",                   code: "EURS",    decimal: 2,  type: CoinType(erc20Address: "0xdB25f211AB05b1c97D595516F45794528a807ad8")),
        Coin(id: "SNT",       title: "Status",                        code: "SNT",     decimal: 18, type: CoinType(erc20Address: "0x744d70FDBE2Ba4CF95131626614a1763DF805B9E")),
        Coin(id: "STORJ",     title: "Storj",                         code: "STORJ",   decimal: 8,  type: CoinType(erc20Address: "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac")),
        Coin(id: "SWINGBY",   title: "Swingby Token",                 code: "SWINGBY", decimal: 8,  type: .binance(symbol: "SWINGBY-888")),
        Coin(id: "SXP",       title: "Swipe",                         code: "SXP",     decimal: 18, type: CoinType(erc20Address: "0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9")),
        Coin(id: "CHSB",      title: "SwissBorg",                     code: "CHSB",    decimal: 8,  type: CoinType(erc20Address: "0xba9d4199fab4f26efe3551d490e3821486f135ba")),
        Coin(id: "TRB",       title: "Tellor Tributes",               code: "TRB",     decimal: 18, type: CoinType(erc20Address: "0x0ba45a8b5d5575935b8158a88c631e9f9c95a2e5")),
        Coin(id: "USDT",      title: "Tether USD",                    code: "USDT",    decimal: 6,  type: CoinType(erc20Address: "0xdAC17F958D2ee523a2206206994597C13D831ec7")),
        Coin(id: "MTXLT",     title: "Tixl",                          code: "MTXLT",   decimal: 8,  type: .binance(symbol: "MTXLT-286")),
        Coin(id: "TAUD",      title: "TrueAUD",                       code: "TAUD",    decimal: 18, type: CoinType(erc20Address: "0x00006100F7090010005F1bd7aE6122c3C2CF0090")),
        Coin(id: "TAUDB",     title: "TrueAUD",                       code: "TAUDB",   decimal: 8,  type: .binance(symbol: "TAUDB-888")),
        Coin(id: "TCAD",      title: "TrueCAD",                       code: "TCAD",    decimal: 18, type: CoinType(erc20Address: "0x00000100F2A2bd000715001920eB70D229700085")),
        Coin(id: "TGBP",      title: "TrueGBP",                       code: "TGBP",    decimal: 18, type: CoinType(erc20Address: "0x00000000441378008ea67f4284a57932b1c000a5")),
        Coin(id: "THKD",      title: "TrueHKD",                       code: "THKD",    decimal: 18, type: CoinType(erc20Address: "0x0000852600ceb001e08e00bc008be620d60031f2")),
        Coin(id: "THKDB",     title: "TrueHKD",                       code: "THKDB",   decimal: 8,  type: .binance(symbol: "THKDB-888")),
        Coin(id: "TUSD",      title: "TrueUSD",                       code: "TUSD",    decimal: 18, type: CoinType(erc20Address: "0x0000000000085d4780B73119b644AE5ecd22b376")),
        Coin(id: "TUSDB",     title: "TrueUSD",                       code: "TUSDB",   decimal: 8,  type: .binance(symbol: "TUSDB-888")),
        Coin(id: "TRST",      title: "Trustcoin",                     code: "TRST",    decimal: 6,  type: CoinType(erc20Address: "0xcb94be6f13a1182e4a4b6140cb7bf2025d28e41b")),
        Coin(id: "SWAP",      title: "TrustSwap",                     code: "SWAP",    decimal: 18, type: CoinType(erc20Address: "0xCC4304A31d09258b0029eA7FE63d032f52e44EFe")),
        Coin(id: "UBT",       title: "UniBright",                     code: "UBT",     decimal: 6,  type: CoinType(erc20Address: "0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e")),
        Coin(id: "SOCKS",     title: "Unisocks Edition 0",            code: "SOCKS",   decimal: 18, type: CoinType(erc20Address: "0x23b608675a2b2fb1890d3abbd85c5775c51691d5")),
        Coin(id: "UMA",       title: "UMA Voting Token v1",           code: "UMA",     decimal: 18, type: CoinType(erc20Address: "0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828")),
        Coin(id: "UNI",       title: "Uniswap",                       code: "UNI",     decimal: 18, type: CoinType(erc20Address: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984")),
        Coin(id: "USDC",      title: "USD Coin",                      code: "USDC",    decimal: 6,  type: CoinType(erc20Address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")),
        Coin(id: "USDSB",     title: "USDS",                          code: "USDSB",   decimal: 8,  type: .binance(symbol: "USDSB-1AC")),
        Coin(id: "USDT-BEP2", title: "USDTBEP2",                      code: "USDT",    decimal: 8,  type: .binance(symbol: "USDT-6D8")),
        Coin(id: "VERI",      title: "Veritaseum",                    code: "VERI",    decimal: 18, type: CoinType(erc20Address: "0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374")),
        Coin(id: "WTC",       title: "Waltonchain",                   code: "WTC",     decimal: 18, type: CoinType(erc20Address: "0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74")),
        Coin(id: "WICC",      title: "WaykiChain Coin",               code: "WICC",    decimal: 8,  type: .binance(symbol: "WICC-01D")),
        Coin(id: "WRX",       title: "WazirX Token",                  code: "WRX",     decimal: 8,  type: .binance(symbol: "WRX-ED1")),
        Coin(id: "WBTC",      title: "Wrapped Bitcoin",               code: "WBTC",    decimal: 8,  type: CoinType(erc20Address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599")),
        Coin(id: "WETH",      title: "Wrapped Ethereum",              code: "WETH",    decimal: 18, type: CoinType(erc20Address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")),
        Coin(id: "WFIL",      title: "Wrapped Filecoin",              code: "WFIL",    decimal: 18, type: CoinType(erc20Address: "0x6e1A19F235bE7ED8E3369eF73b196C07257494DE")),
        Coin(id: "XIO",       title: "XIO Network",                   code: "XIO",     decimal: 18, type: CoinType(erc20Address: "0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704")),

    ]

    private let testNetCoins = [
        Coin(id: "BTC",       title: "Bitcoin",                       code: "BTC",     decimal: 8,  type: .bitcoin),
        Coin(id: "LTC",       title: "Litecoin",                      code: "LTC",     decimal: 8,  type: .litecoin),
        ethereumCoin,
        Coin(id: "BCH",       title: "Bitcoin Cash",                  code: "BCH",     decimal: 8,  type: .bitcoinCash),
        Coin(id: "DASH",      title: "Dash",                          code: "DASH",    decimal: 8,  type: .dash),
        Coin(id: "BNB",       title: "Binance Chain",                 code: "BNB",     decimal: 8,  type: .binance(symbol: "BNB")),
        Coin(id: "ZEC",       title: "Zcash",                         code: "ZEC",     decimal: 8,  type: .zcash),
        Coin(id: "EOS",       title: "EOS",                           code: "EOS",     decimal: 4,  type: .eos(token: "eosio.token", symbol: "EOS")),
        Coin(id: "DAI",       title: "Dai",                           code: "DAI",     decimal: 18, type: CoinType(erc20Address: "0xad6d458402f60fd3bd25163575031acdce07538d")),
        Coin(id: "WEENUS",    title: "WEENUS",                        code: "WEENUS",  decimal: 18, type: CoinType(erc20Address: "0x101848D5C5bBca18E6b4431eEdF6B95E9ADF82FA")),
    ]

}
