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
    let feeRateAdjustedForCurrencyCodes: [String] = ["USD", "EUR"]

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
        ]
    }

    var defaultCoins: [Coin] {
        testMode ? testNetCoins : mainNetCoins
    }

    private let mainNetCoins = [
        Coin(id: "BTC",       title: "Bitcoin",                           code: "BTC",     decimal: 8,  type: .bitcoin),
        Coin(id: "LTC",       title: "Litecoin",                          code: "LTC",     decimal: 8,  type: .litecoin),
        ethereumCoin,
        Coin(id: "BCH",       title: "Bitcoin Cash",                      code: "BCH",     decimal: 8,  type: .bitcoinCash),
        Coin(id: "DASH",      title: "Dash",                              code: "DASH",    decimal: 8,  type: .dash),
        Coin(id: "BNB",       title: "Binance Chain",                     code: "BNB",     decimal: 8,  type: .binance(symbol: "BNB")),
        Coin(id: "ZEC",       title: "Zcash",                             code: "ZEC",     decimal: 8,  type: .zcash),
        Coin(id: "$BASED",    title: "$BASED",                            code: "$BASED",  decimal: 18, type: .erc20(address: "0x68A118Ef45063051Eac49c7e647CE5Ace48a68a5")),
        Coin(id: "ZCN",       title: "0chain",                            code: "ZCN",     decimal: 10, type: .erc20(address: "0xb9EF770B6A5e12E45983C5D80545258aA38F3B78")),
        Coin(id: "ZRX",       title: "0x Protocol",                       code: "ZRX",     decimal: 18, type: .erc20(address: "0xE41d2489571d322189246DaFA5ebDe1F4699F498")),
        Coin(id: "1INCH",     title: "1INCH Token",                       code: "1INCH",   decimal: 18, type: .erc20(address: "0x111111111117dc0aa78b770fa6a738034120c302")),
        Coin(id: "MPH",       title: "88mph.app",                         code: "MPH",     decimal: 18, type: .erc20(address: "0x8888801af4d980682e47f1a9036e589479e835c5")),
        Coin(id: "LEND",      title: "Aave",                              code: "LEND",    decimal: 18, type: .erc20(address: "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03")),
        Coin(id: "AAVE",      title: "Aave Token",                        code: "AAVE",    decimal: 18, type: .erc20(address: "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9")),
        Coin(id: "AAVEDAI",   title: "Aave DAI",                          code: "ADAI",    decimal: 18, type: .erc20(address: "0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d")),
        Coin(id: "ELF",       title: "Aelf",                              code: "ELF",     decimal: 18, type: .erc20(address: "0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e")),
        Coin(id: "AST",       title: "AirSwap",                           code: "AST",     decimal: 4,  type: .erc20(address: "0x27054b13b1b798b345b591a4d22e6562d47ea75a")),
        Coin(id: "AKRO",      title: "Akropolis",                         code: "AKRO",    decimal: 18, type: .erc20(address: "0x8ab7404063ec4dbcfd4598215992dc3f8ec853d7")),
        Coin(id: "ALBT",      title: "AllianceBlock Token",               code: "ALBT",    decimal: 18, type: .erc20(address: "0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0")),
        Coin(id: "ALPHA",     title: "AlphaToken",                        code: "ALPHA",   decimal: 18, type: .erc20(address: "0xa1faa113cbe53436df28ff0aee54275c13b40975")),
        Coin(id: "AMON",      title: "Amon",                              code: "AMN",     decimal: 18, type: .erc20(address: "0x737f98ac8ca59f2c68ad658e3c3d8c8963e40a4c")),
        Coin(id: "AMPL",      title: "Ampleforth",                        code: "AMPL",    decimal: 9,  type: .erc20(address: "0xd46ba6d942050d489dbd938a2c909a5d5039a161")),
        Coin(id: "ANKR",      title: "Ankr Network",                      code: "ANKR",    decimal: 8,  type: .binance(symbol: "ANKR-E97")),
        Coin(id: "API3",      title: "API3",                              code: "API3",    decimal: 18, type: .erc20(address: "0x0b38210ea11411557c13457D4dA7dC6ea731B88a")),
        Coin(id: "APY",       title: "APY Governance Token",              code: "APY",     decimal: 18, type: .erc20(address: "0x95a4492F028aa1fd432Ea71146b433E7B4446611")),
        Coin(id: "ANT",       title: "Aragon",                            code: "ANT",     decimal: 18, type: .erc20(address: "0x960b236A07cf122663c4303350609A66A7B288C0")),
        Coin(id: "ANJ",       title: "Aragon Court",                      code: "ANJ",     decimal: 18, type: .erc20(address: "0xcD62b1C403fa761BAadFC74C525ce2B51780b184")),
        Coin(id: "AUC",       title: "Auctus",                            code: "AUC",     decimal: 18, type: .erc20(address: "0xc12d099be31567add4e4e4d0d45691c3f58f5663")),
        Coin(id: "REP",       title: "Augur",                             code: "REP",     decimal: 18, type: .erc20(address: "0x1985365e9f78359a9B6AD760e32412f4a445E862")),
        Coin(id: "BAC",       title: "BAC",                               code: "BAC",     decimal: 18, type: .erc20(address: "0x3449FC1Cd036255BA1EB19d65fF4BA2b8903A69a")),
        Coin(id: "BADGER",    title: "Badger",                            code: "BADGER",  decimal: 18, type: .erc20(address: "0x3472a5a71965499acd81997a54bba8d852c6e53d")),
        Coin(id: "BAL",       title: "Balancer",                          code: "BAL",     decimal: 18, type: .erc20(address: "0xba100000625a3754423978a60c9317c58a424e3D")),
        Coin(id: "BNT",       title: "Bancor",                            code: "BNT",     decimal: 18, type: .erc20(address: "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C")),
        Coin(id: "BAND",      title: "Band Protocol",                     code: "BAND",    decimal: 18, type: .erc20(address: "0xba11d00c5f74255f56a5e366f4f77f5a186d7f55")),
        Coin(id: "BOND",      title: "BarnBridge",                        code: "BOND",    decimal: 18, type: .erc20(address: "0x0391D2021f89DC339F60Fff84546EA23E337750f")),
        Coin(id: "BASE",      title: "Base Protocol",                     code: "BASE",    decimal: 9,  type: .erc20(address: "0x07150e919b4de5fd6a63de1f9384828396f25fdc")),
        Coin(id: "BAT",       title: "Basic Attention Token",             code: "BAT",     decimal: 18, type: .erc20(address: "0x0D8775F648430679A709E98d2b0Cb6250d2887EF")),
        Coin(id: "BID",       title: "Bidao",                             code: "BID",     decimal: 18, type: .erc20(address: "0x25e1474170c4c0aA64fa98123bdc8dB49D7802fa")),
        Coin(id: "BNB-ERC20", title: "Binance ERC20",                     code: "BNB",     decimal: 18, type: .erc20(address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")),
        Coin(id: "BUSD",      title: "Binance USD",                       code: "BUSD",    decimal: 8,  type: .binance(symbol: "BUSD-BD1")),
        Coin(id: "BTCB",      title: "Bitcoin BEP2",                      code: "BTCB",    decimal: 8,  type: .binance(symbol: "BTCB-1DE")),
        Coin(id: "BLT",       title: "Bloom",                             code: "BLT",     decimal: 18, type: .erc20(address: "0x107c4504cd79c5d2696ea0030a8dd4e92601b82e")),
        Coin(id: "BONDLY",    title: "Bondly Token",                      code: "BONDLY",  decimal: 18, type: .erc20(address: "0xd2dda223b2617cb616c1580db421e4cfae6a8a85")),
        Coin(id: "BZRX",      title: "bZx Protocol Token",                code: "BZRX",    decimal: 18, type: .erc20(address: "0x56d811088235F11C8920698a204A5010a788f4b3")),
        Coin(id: "CAS",       title: "Cashaa",                            code: "CAS",     decimal: 8,  type: .binance(symbol: "CAS-167")),
        Coin(id: "CELR",      title: "Celer Network",                     code: "CELR",    decimal: 18, type: .erc20(address: "0x4f9254c83eb525f9fcf346490bbb3ed28a81c667")),
        Coin(id: "CEL",       title: "Celsius",                           code: "CEL",     decimal: 4,  type: .erc20(address: "0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d")),
        Coin(id: "CHAI",      title: "Chai",                              code: "CHAI",    decimal: 18, type: .erc20(address: "0x06AF07097C9Eeb7fD685c692751D5C66dB49c215")),
        Coin(id: "CHAIN",     title: "Chain Games",                       code: "CHAIN",   decimal: 18, type: .erc20(address: "0xC4C2614E694cF534D407Ee49F8E44D125E4681c4")),
        Coin(id: "LINK",      title: "Chainlink",                         code: "LINK",    decimal: 18, type: .erc20(address: "0x514910771AF9Ca656af840dff83E8264EcF986CA")),
        Coin(id: "CHZ",       title: "Chiliz",                            code: "CHZ",     decimal: 8,  type: .binance(symbol: "CHZ-ECD")),
        Coin(id: "CVC",       title: "Civic",                             code: "CVC",     decimal: 8,  type: .erc20(address: "0x41e5560054824ea6b0732e656e3ad64e20e94e45")),
        Coin(id: "COMP",      title: "Compound",                          code: "COMP",    decimal: 18, type: .erc20(address: "0xc00e94cb662c3520282e6f5717214004a7f26888")),
        Coin(id: "CDAI",      title: "Compound Dai",                      code: "CDAI",    decimal: 8,  type: .erc20(address: "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643")),
        Coin(id: "CSAI",      title: "Compound Sai",                      code: "CSAI",    decimal: 8,  type: .erc20(address: "0xf5dce57282a584d2746faf1593d3121fcac444dc")),
        Coin(id: "CUSDC",     title: "Compound USDC",                     code: "CUSDC",   decimal: 8,  type: .erc20(address: "0x39aa39c021dfbae8fac545936693ac917d5e7563")),
        Coin(id: "COS",       title: "Contentos",                         code: "COS",     decimal: 8,  type: .binance(symbol: "COS-2E4")),
        Coin(id: "CREAM",     title: "Cream",                             code: "CREAM",   decimal: 18, type: .erc20(address: "0x2ba592f78db6436527729929aaf6c908497cb200")),
        Coin(id: "CRPT",      title: "Crypterium",                        code: "CRPT",    decimal: 8,  type: .binance(symbol: "CRPT-8C9")),
        Coin(id: "CRO",       title: "Crypto.com Coin",                   code: "CRO",     decimal: 8,  type: .erc20(address: "0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b")),
        Coin(id: "CRV",       title: "Curve DAO Token",                   code: "CRV",     decimal: 18, type: .erc20(address: "0xD533a949740bb3306d119CC777fa900bA034cd52")),
        Coin(id: "CORE",      title: "cVault.finance",                    code: "CORE",    decimal: 18, type: .erc20(address: "0x62359ed7505efc61ff1d56fef82158ccaffa23d7")),
        Coin(id: "DAI",       title: "Dai",                               code: "DAI",     decimal: 18, type: .erc20(address: "0x6b175474e89094c44da98b954eedeac495271d0f")),
        Coin(id: "RING",      title: "Darwinia Network",                  code: "RING",    decimal: 18, type: .erc20(address: "0x9469d013805bffb7d3debe5e7839237e535ec483")),
        Coin(id: "GEN",       title: "DAOstack",                          code: "GEN",     decimal: 18, type: .erc20(address: "0x543ff227f64aa17ea132bf9886cab5db55dcaddf")),
        Coin(id: "MANA",      title: "Decentraland",                      code: "MANA",    decimal: 18, type: .erc20(address: "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942")),
        Coin(id: "DPI",       title: "DefiPulse Index",                   code: "DPI",     decimal: 18, type: .erc20(address: "0x1494ca1f11d487c2bbe4543e90080aeba4ba3c2b")),
        Coin(id: "DYP",       title: "DeFiYieldProtocol",                 code: "DYP",     decimal: 18, type: .erc20(address: "0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17")),
        Coin(id: "DEFO",      title: "DefHold",                           code: "DEFO",    decimal: 18, type: .erc20(address: "0xe481f2311C774564D517d015e678c2736A25Ddd3")),
        Coin(id: "DEGO",      title: "dego.finance",                      code: "DEGO",    decimal: 18, type: .erc20(address: "0x88ef27e69108b2633f8e1c184cc37940a075cc02")),
        Coin(id: "DEUS",      title: "DEUS",                              code: "DEUS",    decimal: 18, type: .erc20(address: "0x3b62F3820e0B035cc4aD602dECe6d796BC325325")),
        Coin(id: "USDx",      title: "dForce",                            code: "USDx",    decimal: 18, type: .erc20(address: "0xeb269732ab75A6fD61Ea60b06fE994cD32a83549")),
        Coin(id: "DHT",       title: "dHedge DAO Token",                  code: "DHT",     decimal: 18, type: .erc20(address: "0xca1207647Ff814039530D7d35df0e1Dd2e91Fa84")),
        Coin(id: "DUSD",      title: "DefiDollar",                        code: "DUSD",    decimal: 18, type: .erc20(address: "0x5bc25f649fc4e26069ddf4cf4010f9f706c23831")),
        Coin(id: "DEFI5",     title: "DEFI Top 5 Tokens Index",           code: "DEFI5",   decimal: 18, type: .erc20(address: "0xfa6de2697d59e88ed7fc4dfe5a33dac43565ea41")),
        Coin(id: "DIA",       title: "DIA",                               code: "DIA",     decimal: 18, type: .erc20(address: "0x84ca8bc7997272c7cfb4d0cd3d55cd942b3c9419")),
        Coin(id: "DGD",       title: "DigixDAO",                          code: "DGD",     decimal: 9,  type: .erc20(address: "0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A")),
        Coin(id: "DGX",       title: "Digix Gold Token",                  code: "DGX",     decimal: 9,  type: .erc20(address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF")),
        Coin(id: "DNT",       title: "District0x",                        code: "DNT",     decimal: 18, type: .erc20(address: "0x0abdace70d3790235af448c88547603b945604ea")),
        Coin(id: "DMG",       title: "DMM:Governance",                    code: "DMG",     decimal: 18, type: .erc20(address: "0xEd91879919B71bB6905f23af0A68d231EcF87b14")),
        Coin(id: "DOS",       title: "DOS Network",                       code: "DOS",     decimal: 8,  type: .binance(symbol: "DOS-120")),
        Coin(id: "DOS-ERC20", title: "DOS Network",                       code: "DOS",     decimal: 18, type: .erc20(address: "0x0A913beaD80F321E7Ac35285Ee10d9d922659cB7")),
        Coin(id: "DDIM",      title: "DuckDaoDime",                       code: "DDIM",    decimal: 18, type: .erc20(address: "0xfbeea1c75e4c4465cb2fccc9c6d6afe984558e20")),
        Coin(id: "DSD",       title: "Dynamic Set Dollar",                code: "DSD",     decimal: 18, type: .erc20(address: "0xbd2f0cd039e0bfcf88901c98c0bfac5ab27566e3")),
        Coin(id: "eXRD",      title: "E-RADIX",                           code: "eXRD",    decimal: 18, type: .erc20(address: "0x6468e79A80C0eaB0F9A2B574c8d5bC374Af59414")),
        Coin(id: "ENJ",       title: "Enjin Coin",                        code: "ENJ",     decimal: 18, type: .erc20(address: "0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c")),
        Coin(id: "ESD",       title: "Empty Set Dollar",                  code: "ESD",     decimal: 18, type: .erc20(address: "0x36f3fd68e7325a35eb768f1aedaae9ea0689d723")),
        Coin(id: "ETH-BEP2",  title: "ETH BEP2",                          code: "ETH",     decimal: 8,  type: .binance(symbol: "ETH-1C9")),
        Coin(id: "DIP",       title: "Etherisc DIP Token",                code: "DIP",     decimal: 18, type: .erc20(address: "0xc719d010b63e5bbf2c0551872cd5316ed26acd83")),
        Coin(id: "ETHYS",     title: "Ethereum Stake",                    code: "ETHYS",   decimal: 18, type: .erc20(address: "0xD0d3EbCAd6A20ce69BC3Bc0e1ec964075425e533")),
        Coin(id: "FSW",       title: "FalconSwap Token",                  code: "FSW",     decimal: 18, type: .erc20(address: "0xfffffffFf15AbF397dA76f1dcc1A1604F45126DB")),
        Coin(id: "FARM",      title: "FARM Reward Token",                 code: "FARM",    decimal: 18, type: .erc20(address: "0xa0246c9032bC3A600820415aE600c6388619A14D")),
        Coin(id: "FNK",       title: "Finiko",                            code: "FNK",     decimal: 18, type: .erc20(address: "0xb5fe099475d3030dde498c3bb6f3854f762a48ad")),
        Coin(id: "FLASH",     title: "Flash Token",                       code: "FLASH",   decimal: 18, type: .erc20(address: "0xb4467e8d621105312a914f1d42f10770c0ffe3c8")),
        Coin(id: "FLUX",      title: "FLUX",                              code: "FLUX",    decimal: 18, type: .erc20(address: "0x469eDA64aEd3A3Ad6f868c44564291aA415cB1d9")),
        Coin(id: "FOAM",      title: "FOAM Token",                        code: "FOAM",    decimal: 18, type: .erc20(address: "0x4946fcea7c692606e8908002e55a582af44ac121")),
        Coin(id: "FRAX",      title: "Frax",                              code: "FRAX",    decimal: 18, type: .erc20(address: "0x853d955acef822db058eb8505911ed77f175b99e")),
        Coin(id: "FTT",       title: "FTX Token",                         code: "FTT",     decimal: 18, type: .erc20(address: "0x50d1c9771902476076ecfc8b2a83ad6b9355a4c9")),
        Coin(id: "FUN",       title: "FunFair",                           code: "FUN",     decimal: 8,  type: .erc20(address: "0x419d0d8bdd9af5e606ae2232ed285aff190e711b")),
        Coin(id: "COMBO",     title: "Furucombo",                         code: "COMBO",   decimal: 18, type: .erc20(address: "0xffffffff2ba8f66d4e51811c5190992176930278")),
        Coin(id: "FYZ",       title: "FYOOZ",                             code: "FYZ",     decimal: 18, type: .erc20(address: "0x6BFf2fE249601ed0Db3a87424a2E923118BB0312")),
        Coin(id: "GST2",      title: "Gas Token Two",                     code: "GST2",    decimal: 2,  type: .erc20(address: "0x0000000000b3f879cb30fe243b4dfee438691c04")),
        Coin(id: "GT",        title: "GateChainToken",                    code: "GT",      decimal: 18, type: .erc20(address: "0xe66747a101bff2dba3697199dcce5b743b454759")),
        Coin(id: "GUSD",      title: "Gemini Dollar",                     code: "GUSD",    decimal: 2,  type: .erc20(address: "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd")),
        Coin(id: "GTO",       title: "Gifto",                             code: "GTO",     decimal: 8,  type: .binance(symbol: "GTO-908")),
        Coin(id: "GNO",       title: "Gnosis",                            code: "GNO",     decimal: 18, type: .erc20(address: "0x6810e776880c02933d47db1b9fc05908e5386b96")),
        Coin(id: "GLM",       title: "Golem",                             code: "GLM",     decimal: 18, type: .erc20(address: "0x7DD9c5Cba05E151C895FDe1CF355C9A1D5DA6429")),
        Coin(id: "GRT",       title: "Graph Token",                       code: "GRT",     decimal: 18, type: .erc20(address: "0xc944e90c64b2c07662a292be6244bdf05cda44a7")),
        Coin(id: "GRID",      title: "Grid",                              code: "GRID",    decimal: 12, type: .erc20(address: "0x12b19d3e2ccc14da04fae33e63652ce469b3f2fd")),
        Coin(id: "XCHF",      title: "GryptoFranc",                       code: "XCHF",    decimal: 18, type: .erc20(address: "0xb4272071ecadd69d933adcd19ca99fe80664fc08")),
        Coin(id: "CC10",      title: "Cryptocurrency Top10 Tokens Index", code: "CC10",    decimal: 18, type: .erc20(address: "0x17ac188e09a7890a1844e5e65471fe8b0ccfadf3")),
        Coin(id: "ONE",       title: "Harmony",                           code: "ONE",     decimal: 8,  type: .binance(symbol: "ONE-5F9")),
        Coin(id: "HEGIC",     title: "Hegic",                             code: "HEGIC",   decimal: 18, type: .erc20(address: "0x584bC13c7D411c00c01A62e8019472dE68768430")),
        Coin(id: "HEDG",      title: "HEDG",                              code: "HEDG",    decimal: 18, type: .erc20(address: "0xf1290473e210b2108a85237fbcd7b6eb42cc654f")),
        Coin(id: "HEZ",       title: "Hermez Network Token",              code: "HEZ",     decimal: 18, type: .erc20(address: "0xEEF9f339514298C6A857EfCfC1A762aF84438dEE")),
        Coin(id: "HLAND",     title: "Hland Token",                       code: "HLAND",   decimal: 18, type: .erc20(address: "0xba7b2c094c1a4757f9534a37d296a3bed7f544dc")),
        Coin(id: "HOT",       title: "Holo",                              code: "HOT",     decimal: 18, type: .erc20(address: "0x6c6EE5e31d828De241282B9606C8e98Ea48526E2")),
        Coin(id: "HH",        title: "Holyheld",                          code: "HH",      decimal: 18, type: .erc20(address: "0x3FA729B4548beCBAd4EaB6EF18413470e6D5324C")),
        Coin(id: "HT",        title: "Huobi Token",                       code: "HT",      decimal: 18, type: .erc20(address: "0x6f259637dcD74C767781E37Bc6133cd6A68aa161")),
        Coin(id: "HUSD",      title: "HUSD",                              code: "HUSD",    decimal: 8,  type: .erc20(address: "0xdf574c24545e5ffecb9a659c229253d4111d87e1")),
        Coin(id: "IDEX",      title: "IDEX",                              code: "IDEX",    decimal: 18, type: .erc20(address: "0xB705268213D593B8FD88d3FDEFF93AFF5CbDcfAE")),
        Coin(id: "IDLE",      title: "Idle",                              code: "IDLE",    decimal: 18, type: .erc20(address: "0x875773784Af8135eA0ef43b5a374AaD105c5D39e")),
        Coin(id: "IOTX",      title: "IoTeX",                             code: "IOTX",    decimal: 18, type: .erc20(address: "0x6fb3e0a217407efff7ca062d46c26e5d60a14d69")),
        Coin(id: "IRIS",      title: "IRISnet",                           code: "IRIS",    decimal: 8,  type: .binance(symbol: "IRIS-D88")),
        Coin(id: "KEEP",      title: "KEEP Token",                        code: "KEEP",    decimal: 18, type: .erc20(address: "0x85eee30c52b0b379b046fb0f85f4f3dc3009afec")),
        Coin(id: "KP3R",      title: "Keep3rV1",                          code: "KP3R",    decimal: 18, type: .erc20(address: "0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44")),
        Coin(id: "PNK",       title: "Kleros",                            code: "PNK",     decimal: 18, type: .erc20(address: "0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d")),
        Coin(id: "KCS",       title: "KuCoin Token",                      code: "KCS",     decimal: 6,  type: .erc20(address: "0x039B5649A59967e3e936D7471f9c3700100Ee1ab")),
        Coin(id: "KNC",       title: "Kyber Network Crystal",             code: "KNC",     decimal: 18, type: .erc20(address: "0xdd974D5C2e2928deA5F71b9825b8b646686BD200")),
        Coin(id: "LGCY",      title: "LGCY Network",                      code: "LGCY",    decimal: 18, type: .erc20(address: "0xaE697F994Fc5eBC000F8e22EbFfeE04612f98A0d")),
        Coin(id: "LDO",       title: "Lido DAO Token",                    code: "LDO",     decimal: 18, type: .erc20(address: "0x5a98fcbea516cf06857215779fd812ca3bef1b32")),
        Coin(id: "LINA",      title: "Linear Token",                      code: "LINA",    decimal: 18, type: .erc20(address: "0x3E9BC21C9b189C09dF3eF1B824798658d5011937")),
        Coin(id: "LPT",       title: "Livepeer Token",                    code: "LPT",     decimal: 18, type: .erc20(address: "0x58b6a8a3302369daec383334672404ee733ab239")),
        Coin(id: "LQD",       title: "Liquidity Network",                 code: "LQD",     decimal: 18, type: .erc20(address: "0xd29f0b5b3f50b07fe9a9511f7d86f4f4bac3f8c4")),
        Coin(id: "LON",       title: "LON Token",                         code: "LON",     decimal: 18, type: .erc20(address: "0x0000000000095413afc295d19edeb1ad7b71c952")),
        Coin(id: "LOOM",      title: "Loom Network",                      code: "LOOM",    decimal: 18, type: .erc20(address: "0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0")),
        Coin(id: "LRC",       title: "Loopring",                          code: "LRC",     decimal: 18, type: .erc20(address: "0xEF68e7C694F40c8202821eDF525dE3782458639f")),
        Coin(id: "LRC",       title: "LoopringCoin V2",                   code: "LRC",     decimal: 18, type: .erc20(address: "0xbbbbca6a901c926f240b89eacb641d8aec7aeafd")),
        Coin(id: "LTO",       title: "LTO Network",                       code: "LTO",     decimal: 8,  type: .binance(symbol: "LTO-BDF")),
        Coin(id: "MFT",       title: "Mainframe Token",                   code: "MFT",     decimal: 18, type: .erc20(address: "0xdf2c7238198ad8b389666574f2d8bc411a4b7428")),
        Coin(id: "MATIC",     title: "Matic Token",                       code: "MATIC",   decimal: 18, type: .erc20(address: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0")),
        Coin(id: "MATIC-BEP2",title: "Matic Token",                       code: "MATIC",   decimal: 8,  type: .binance(symbol: "MATIC-84A")),
        Coin(id: "MKR",       title: "Maker",                             code: "MKR",     decimal: 18, type: .erc20(address: "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2")),
        Coin(id: "MLN",       title: "Melon Token",                       code: "MLN",     decimal: 18, type: .erc20(address: "0xec67005c4e498ec7f55e092bd1d35cbc47c91892")),
        Coin(id: "MET",       title: "Metronome",                         code: "MET",     decimal: 18, type: .erc20(address: "0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e")),
        Coin(id: "MCO",       title: "MCO",                               code: "MCO",     decimal: 8,  type: .erc20(address: "0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d")),
        Coin(id: "MCB",       title: "MCDEX Token",                       code: "MCB",     decimal: 18, type: .erc20(address: "0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42")),
        Coin(id: "MEME",      title: "MEME",                              code: "MEME",    decimal: 8,  type: .erc20(address: "0xd5525d397898e5502075ea5e830d8914f6f0affe")),
        Coin(id: "MTA",       title: "Meta",                              code: "MTA",     decimal: 18, type: .erc20(address: "0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2")),
        Coin(id: "MUSD",      title: "mStable USD",                       code: "MUSD",    decimal: 18, type: .erc20(address: "0xe2f2a5c287993345a840db3b0845fbc70f5935a5")),
        Coin(id: "TKN",       title: "Monolith",                          code: "TKN",     decimal: 8,  type: .erc20(address: "0xaaaf91d9b90df800df4f55c205fd6989c977e73a")),
        Coin(id: "MX",        title: "MX Token",                          code: "MX",      decimal: 18, type: .erc20(address: "0x11eef04c884e24d9b7b4760e7476d06ddf797f36")),
        Coin(id: "USDN",      title: "Neatrino USD",                      code: "USDN",    decimal: 18, type: .erc20(address: "0x674C6Ad92Fd080e4004b2312b45f796a192D27a0")),
        Coin(id: "NEST",      title: "NEST",                              code: "NEST",    decimal: 18, type: .erc20(address: "0x04abeda201850ac0124161f037efd70c74ddc74c")),
        Coin(id: "NEXO",      title: "Nexo",                              code: "NEXO",    decimal: 18, type: .erc20(address: "0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206")),
        Coin(id: "Nsure",     title: "Nsure Network Token",               code: "Nsure",   decimal: 18, type: .erc20(address: "0x20945cA1df56D237fD40036d47E866C7DcCD2114")),
        Coin(id: "NMR",       title: "Numeraire",                         code: "NMR",     decimal: 18, type: .erc20(address: "0x1776e1f26f98b1a5df9cd347953a26dd3cb46671")),
        Coin(id: "NXM",       title: "NXM",                               code: "NXM",     decimal: 18, type: .erc20(address: "0xd7c49cee7e9188cca6ad8ff264c1da2e69d4cf3b")),
        Coin(id: "OCEAN",     title: "Ocean Token",                       code: "OCEAN",   decimal: 18, type: .erc20(address: "0x967da4048cD07aB37855c090aAF366e4ce1b9F48")),
        Coin(id: "OCTO",      title: "Octo.fi",                           code: "OCTO",    decimal: 18, type: .erc20(address: "0x7240aC91f01233BaAf8b064248E80feaA5912BA3")),
        Coin(id: "XFT",       title: "Offshift",                          code: "XFT",     decimal: 18, type: .erc20(address: "0xabe580e7ee158da464b51ee1a83ac0289622e6be")),
        Coin(id: "COVER",     title: "Old Cover Protocol",                code: "COVER",   decimal: 18, type: .erc20(address: "0x5D8d9F5b96f4438195BE9b99eee6118Ed4304286")),
        Coin(id: "OMG",       title: "OmiseGO",                           code: "OMG",     decimal: 18, type: .erc20(address: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07")),
        Coin(id: "ORAI",      title: "Oraichain Token",                   code: "ORAI",    decimal: 18, type: .erc20(address: "0x4c11249814f11b9346808179cf06e71ac328c1b5")),
        Coin(id: "OGN",       title: "OriginToken",                       code: "OGN",     decimal: 18, type: .erc20(address: "0x8207c1ffc5b6804f6024322ccf34f29c3541ae26")),
        Coin(id: "ORN",       title: "Orion Protocol",                    code: "ORN",     decimal: 8,  type: .erc20(address: "0x0258F474786DdFd37ABCE6df6BBb1Dd5dfC4434a")),
        Coin(id: "ORBS",      title: "Orbs",                              code: "ORBS",    decimal: 18, type: .erc20(address: "0xff56Cc6b1E6dEd347aA0B7676C85AB0B3D08B0FA")),
        Coin(id: "OXT",       title: "Orchid",                            code: "OXT",     decimal: 18, type: .erc20(address: "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb")),
        Coin(id: "PAN",       title: "Panvala pan",                       code: "PAN",     decimal: 18, type: .erc20(address: "0xD56daC73A4d6766464b38ec6D91eB45Ce7457c44")),
        Coin(id: "PAR",       title: "Parachute",                         code: "PAR",     decimal: 18, type: .erc20(address: "0x1beef31946fbbb40b877a72e4ae04a8d1a5cee06")),
        Coin(id: "PAX",       title: "Paxos Standard",                    code: "PAX",     decimal: 18, type: .erc20(address: "0x8E870D67F660D95d5be530380D0eC0bd388289E1")),
        Coin(id: "PERP",      title: "Perpetual",                         code: "PERP",    decimal: 18, type: .erc20(address: "0xbC396689893D065F41bc2C6EcbeE5e0085233447")),
        Coin(id: "PICKLE",    title: "PickleToken",                       code: "PICKLE",  decimal: 18, type: .erc20(address: "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5")),
        Coin(id: "PLOT",      title: "PLOT",                              code: "PLOT",    decimal: 18, type: .erc20(address: "0x72F020f8f3E8fd9382705723Cd26380f8D0c66Bb")),
        Coin(id: "POA",       title: "POA",                               code: "POA",     decimal: 18, type: .erc20(address: "0x6758b7d441a9739b98552b373703d8d3d14f9e62")),
        Coin(id: "POLS",      title: "PolkastarterToken",                 code: "POLS",    decimal: 18, type: .erc20(address: "0x83e6f1E41cdd28eAcEB20Cb649155049Fac3D5Aa")),
        Coin(id: "POLY",      title: "Polymath",                          code: "POLY",    decimal: 18, type: .erc20(address: "0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC")),
        Coin(id: "PPT",       title: "Populous",                          code: "PPT",     decimal: 8,  type: .erc20(address: "0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a")),
        Coin(id: "pBTC",      title: "pTokens BTC",                       code: "pBTC",    decimal: 18, type: .erc20(address: "0x5228a22e72ccc52d415ecfd199f99d0665e7733b")),
        Coin(id: "NPXS",      title: "Pundi X",                           code: "NPXS",    decimal: 18, type: .erc20(address: "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3")),
        Coin(id: "QNT",       title: "Quant",                             code: "QNT",     decimal: 18, type: .erc20(address: "0x4a220e6096b25eadb88358cb44068a3248254675")),
        Coin(id: "QSP",       title: "Quantstamp",                        code: "QSP",     decimal: 18, type: .erc20(address: "0x99ea4db9ee77acd40b119bd1dc4e33e1c070b80d")),
        Coin(id: "RDN",       title: "Raiden Network Token",              code: "RDN",     decimal: 18, type: .erc20(address: "0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6")),
        Coin(id: "RGT",       title: "Rari Governance Token",             code: "RGT",     decimal: 18, type: .erc20(address: "0xD291E7a03283640FDc51b121aC401383A46cC623")),
        Coin(id: "RENBTC",    title: "renBTC",                            code: "renBTC",  decimal: 8,  type: .erc20(address: "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d")),
        Coin(id: "RENBCH",    title: "renBCH",                            code: "renBCH",  decimal: 8,  type: .erc20(address: "0x459086f2376525bdceba5bdda135e4e9d3fef5bf")),
        Coin(id: "RENZEC",    title: "renZEC",                            code: "renZEC",  decimal: 8,  type: .erc20(address: "0x1c5db575e2ff833e46a2e9864c22f4b22e0b37c2")),
        Coin(id: "REN",       title: "Ren",                               code: "REN",     decimal: 18, type: .erc20(address: "0x408e41876cccdc0f92210600ef50372656052a38")),
        Coin(id: "RARI",      title: "Rarible",                           code: "RARI",    decimal: 18, type: .erc20(address: "0xfca59cd816ab1ead66534d82bc21e7515ce441cf")),
        Coin(id: "RFI",       title: "reflect.finance",                   code: "RFI",     decimal: 9,  type: .erc20(address: "0xA1AFFfE3F4D611d252010E3EAf6f4D77088b0cd7")),
        Coin(id: "REPv2",     title: "Reputation",                        code: "REPv2",   decimal: 8,  type: .erc20(address: "0x221657776846890989a759ba2973e427dff5c9bb")),
        Coin(id: "RSR",       title: "Reserve Rights",                    code: "RSR",     decimal: 18, type: .erc20(address: "0x8762db106b2c2a0bccb3a80d1ed41273552616e8")),
        Coin(id: "REV",       title: "Revain",                            code: "REV",     decimal: 0,  type: .erc20(address: "0x48f775EFBE4F5EcE6e0DF2f7b5932dF56823B990")),
        Coin(id: "RFuel",     title: "Rio Fuel Token",                    code: "RFuel",   decimal: 18, type: .erc20(address: "0xaf9f549774ecedbd0966c52f250acc548d3f36e5")),
        Coin(id: "XRP",       title: "Ripple",                            code: "XRP",     decimal: 8,  type: .binance(symbol: "XRP-BF2")),
        Coin(id: "RLC",       title: "RLC",                               code: "RLC",     decimal: 9,  type: .erc20(address: "0x607F4C5BB672230e8672085532f7e901544a7375")),
        Coin(id: "XRT",       title: "Robonomics",                        code: "XRT",     decimal: 9,  type: .erc20(address: "0x7de91b204c1c737bcee6f000aaa6569cf7061cb7")),
        Coin(id: "RPL",       title: "Rocket Pool",                       code: "RPL",     decimal: 18, type: .erc20(address: "0xb4efd85c19999d84251304bda99e90b92300bd93")),
        Coin(id: "ROOT",      title: "RootKit",                           code: "ROOT",    decimal: 18, type: .erc20(address: "0xCb5f72d37685C3D5aD0bB5F982443BC8FcdF570E")),
        Coin(id: "SAI",       title: "Sai",                               code: "SAI",     decimal: 18, type: .erc20(address: "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359")),
        Coin(id: "SALT",      title: "Salt",                              code: "SALT",    decimal: 8,  type: .erc20(address: "0x4156D3342D5c385a87D264F90653733592000581")),
        Coin(id: "SAND",      title: "SAND",                              code: "SAND",    decimal: 18, type: .erc20(address: "0x3845badAde8e6dFF049820680d1F14bD3903a5d0")),
        Coin(id: "SAN",       title: "Santiment Network Token",           code: "SAN",     decimal: 18, type: .erc20(address: "0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098")),
        Coin(id: "SHARE",     title: "Seigniorage Shares",                code: "SHARE",   decimal: 9,  type: .erc20(address: "0x39795344CBCc76cC3Fb94B9D1b15C23c2070C66D")),
        Coin(id: "KEY",       title: "SelfKey",                           code: "KEY",     decimal: 18, type: .erc20(address: "0x4cc19356f2d37338b9802aa8e8fc58b0373296e7")),
        Coin(id: "SRM",       title: "Serum",                             code: "SRM",     decimal: 6,  type: .erc20(address: "0x476c5E26a75bd202a9683ffD34359C0CC15be0fF")),
        Coin(id: "SHR",       title: "ShareToken",                        code: "SHR",     decimal: 8,  type: .binance(symbol: "SHR-DB6")),
        Coin(id: "XOR",       title: "Sora",                              code: "XOR",     decimal: 18, type: .erc20(address: "0x40FD72257597aA14C7231A7B1aaa29Fce868F677")),
        Coin(id: "SPANK",     title: "SpankChain",                        code: "SPANK",   decimal: 18, type: .erc20(address: "0x42d6622dece394b54999fbd73d108123806f6a18")),
        Coin(id: "SFI",       title: "Spice",                             code: "SFI",     decimal: 18, type: .erc20(address: "0xb753428af26e81097e7fd17f40c88aaa3e04902c")),
        Coin(id: "SPDR",      title: "SpiderDAO Token",                   code: "SPDR",    decimal: 18, type: .erc20(address: "0xbcd4b7de6fde81025f74426d43165a5b0d790fdd")),
        Coin(id: "EURS",      title: "STASIS EURO",                       code: "EURS",    decimal: 2,  type: .erc20(address: "0xdB25f211AB05b1c97D595516F45794528a807ad8")),
        Coin(id: "SNT",       title: "Status",                            code: "SNT",     decimal: 18, type: .erc20(address: "0x744d70FDBE2Ba4CF95131626614a1763DF805B9E")),
        Coin(id: "STORJ",     title: "Storj",                             code: "STORJ",   decimal: 8,  type: .erc20(address: "0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac")),
        Coin(id: "SURF",      title: "SURF.Finance",                      code: "SURF",    decimal: 18, type: .erc20(address: "0xea319e87cf06203dae107dd8e5672175e3ee976c")),
        Coin(id: "SWFL",      title: "Swapfolio",                         code: "SWFL",    decimal: 18, type: .erc20(address: "0xBa21Ef4c9f433Ede00badEFcC2754B8E74bd538A")),
        Coin(id: "SWRV",      title: "Swerve DAO Token",                  code: "SWRV",    decimal: 18, type: .erc20(address: "0xB8BAa0e4287890a5F79863aB62b7F175ceCbD433")),
        Coin(id: "SXP",       title: "Swipe",                             code: "SXP",     decimal: 18, type: .erc20(address: "0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9")),
        Coin(id: "SWISS",     title: "Swiss Token",                       code: "SWISS",   decimal: 18, type: .erc20(address: "0x692eb773e0b5b7a79efac5a015c8b36a2577f65c")),
        Coin(id: "CHSB",      title: "SwissBorg",                         code: "CHSB",    decimal: 8,  type: .erc20(address: "0xba9d4199fab4f26efe3551d490e3821486f135ba")),
        Coin(id: "SNX",       title: "Synthetix",                         code: "SNX",     decimal: 18, type: .erc20(address: "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F")),
        Coin(id: "sETH",      title: "Synth sETH",                        code: "sETH",    decimal: 18, type: .erc20(address: "0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb")),
        Coin(id: "sUSD",      title: "Synth sUSD",                        code: "sUSD",    decimal: 18, type: .erc20(address: "0x57Ab1ec28D129707052df4dF418D58a2D46d5f51")),
        Coin(id: "sXAU",      title: "Synth sXAU",                        code: "sXAU",    decimal: 18, type: .erc20(address: "0x261EfCdD24CeA98652B9700800a13DfBca4103fF")),
        Coin(id: "TBTC",      title: "tBTC",                              code: "TBTC",    decimal: 18, type: .erc20(address: "0x8daebade922df735c38c80c7ebd708af50815faa")),
        Coin(id: "TRB",       title: "Tellor",                            code: "TRB",     decimal: 18, type: .erc20(address: "0x0ba45a8b5d5575935b8158a88c631e9f9c95a2e5")),
        Coin(id: "USDT",      title: "Tether USD",                        code: "USDT",    decimal: 6,  type: .erc20(address: "0xdAC17F958D2ee523a2206206994597C13D831ec7")),
        Coin(id: "FOR",       title: "The Force Token",                   code: "FOR",     decimal: 18, type: .erc20(address: "0x1fcdce58959f536621d76f5b7ffb955baa5a672f")),
        Coin(id: "imBTC",     title: "The Tokenized Bitcoin",             code: "imBTC",   decimal: 8,  type: .erc20(address: "0x3212b29E33587A00FB1C83346f5dBFA69A458923")),
        Coin(id: "RUNE",      title: "THORChain",                         code: "RUNE",    decimal: 8,  type: .binance(symbol: "RUNE-B1A")),
        Coin(id: "MTXLT",     title: "Tixl",                              code: "MTXLT",   decimal: 8,  type: .binance(symbol: "MTXLT-286")),
        Coin(id: "TAUD",      title: "TrueAUD",                           code: "TAUD",    decimal: 18, type: .erc20(address: "0x00006100F7090010005F1bd7aE6122c3C2CF0090")),
        Coin(id: "TAUDB",     title: "TrueAUD",                           code: "TAUDB",   decimal: 8,  type: .binance(symbol: "TAUDB-888")),
        Coin(id: "TCAD",      title: "TrueCAD",                           code: "TCAD",    decimal: 18, type: .erc20(address: "0x00000100F2A2bd000715001920eB70D229700085")),
        Coin(id: "TGBP",      title: "TrueGBP",                           code: "TGBP",    decimal: 18, type: .erc20(address: "0x00000000441378008ea67f4284a57932b1c000a5")),
        Coin(id: "THKD",      title: "TrueHKD",                           code: "THKD",    decimal: 18, type: .erc20(address: "0x0000852600ceb001e08e00bc008be620d60031f2")),
        Coin(id: "THKDB",     title: "TrueHKD",                           code: "THKDB",   decimal: 8,  type: .binance(symbol: "THKDB-888")),
        Coin(id: "TUSD",      title: "TrueUSD",                           code: "TUSD",    decimal: 18, type: .erc20(address: "0x0000000000085d4780B73119b644AE5ecd22b376")),
        Coin(id: "TUSDB",     title: "TrueUSD",                           code: "TUSDB",   decimal: 8,  type: .binance(symbol: "TUSDB-888")),
        Coin(id: "TRST",      title: "Trustcoin",                         code: "TRST",    decimal: 6,  type: .erc20(address: "0xcb94be6f13a1182e4a4b6140cb7bf2025d28e41b")),
        Coin(id: "TRU",       title: "TrustToken",                        code: "TRU",     decimal: 8,  type: .erc20(address: "0x4c19596f5aaff459fa38b0f7ed92f11ae6543784")),
        Coin(id: "SWAP",      title: "TrustSwap",                         code: "SWAP",    decimal: 18, type: .erc20(address: "0xCC4304A31d09258b0029eA7FE63d032f52e44EFe")),
        Coin(id: "TWT",       title: "Trust Wallet",                      code: "TWT",     decimal: 8,  type: .binance(symbol: "TWT-8C2")),
        Coin(id: "UBT",       title: "UniBright",                         code: "UBT",     decimal: 6,  type: .erc20(address: "0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e")),
        Coin(id: "SOCKS",     title: "Unisocks Edition 0",                code: "SOCKS",   decimal: 18, type: .erc20(address: "0x23b608675a2b2fb1890d3abbd85c5775c51691d5")),
        Coin(id: "UMA",       title: "UMA",                               code: "UMA",     decimal: 18, type: .erc20(address: "0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828")),
        Coin(id: "UNI",       title: "Uniswap",                           code: "UNI",     decimal: 18, type: .erc20(address: "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984")),
        Coin(id: "USDC",      title: "USD Coin",                          code: "USDC",    decimal: 6,  type: .erc20(address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")),
        Coin(id: "UTK",       title: "Utrust",                            code: "UTK",     decimal: 18, type: .erc20(address: "0xdc9Ac3C20D1ed0B540dF9b1feDC10039Df13F99c")),
        Coin(id: "VERI",      title: "Veritaseum",                        code: "VERI",    decimal: 18, type: .erc20(address: "0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374")),
        Coin(id: "WTC",       title: "Waltonchain",                       code: "WTC",     decimal: 18, type: .erc20(address: "0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74")),
        Coin(id: "WAVES",     title: "WAVES",                             code: "WAVES",   decimal: 18, type: .erc20(address: "0x1cf4592ebffd730c7dc92c1bdffdfc3b9efcf29a")),
        Coin(id: "WICC",      title: "WaykiChain Coin",                   code: "WICC",    decimal: 8,  type: .binance(symbol: "WICC-01D")),
        Coin(id: "WRX",       title: "WazirX Token",                      code: "WRX",     decimal: 8,  type: .binance(symbol: "WRX-ED1")),
        Coin(id: "WISE",      title: "Wise Token",                        code: "WISE",    decimal: 18, type: .erc20(address: "0x66a0f676479Cee1d7373f3DC2e2952778BfF5bd6")),
        Coin(id: "WHITE",     title: "Whiteheart Token",                  code: "WHITE",   decimal: 18, type: .erc20(address: "0x5f0e628b693018f639d10e4a4f59bd4d8b2b6b44")),
        Coin(id: "wANATHA",   title: "Wrapped ANATHA",                    code: "wANATHA", decimal: 18, type: .erc20(address: "0x3383c5a8969Dc413bfdDc9656Eb80A1408E4bA20")),
        Coin(id: "WBTC",      title: "Wrapped Bitcoin",                   code: "WBTC",    decimal: 8,  type: .erc20(address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599")),
        Coin(id: "WETH",      title: "Wrapped Ethereum",                  code: "WETH",    decimal: 18, type: .erc20(address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")),
        Coin(id: "WFIL",      title: "Wrapped Filecoin",                  code: "WFIL",    decimal: 18, type: .erc20(address: "0x6e1A19F235bE7ED8E3369eF73b196C07257494DE")),
        Coin(id: "MIR",       title: "Wrapped MIR Token",                 code: "MIR",     decimal: 18, type: .erc20(address: "0x09a3EcAFa817268f77BE1283176B946C4ff2E608")),
        Coin(id: "WZEC",      title: "Wrapped ZEC",                       code: "WZEC",    decimal: 18, type: .erc20(address: "0x4a64515e5e1d1073e83f30cb97bed20400b66e10")),
        Coin(id: "STAKE",     title: "xDAI",                              code: "STAKE",   decimal: 18, type: .erc20(address: "0x0Ae055097C6d159879521C384F1D2123D1f195e6")),
        Coin(id: "XIO",       title: "XIO Network",                       code: "XIO",     decimal: 18, type: .erc20(address: "0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704")),
        Coin(id: "YAX",       title: "yAxis",                             code: "YAX",     decimal: 18, type: .erc20(address: "0xb1dc9124c395c1e97773ab855d66e879f053a289")),
        Coin(id: "YFI",       title: "yearn.finance",                     code: "YFI",     decimal: 18, type: .erc20(address: "0x0bc529c00c6401aef6d220be8c6ea1667f6ad93e")),
        Coin(id: "Yf-DAI",    title: "YfDAI.finance",                     code: "Yf-DAI",  decimal: 18, type: .erc20(address: "0xf4CD3d3Fda8d7Fd6C5a500203e38640A70Bf9577")),
        Coin(id: "YFII",      title: "YFII.finance",                      code: "YFII",    decimal: 18, type: .erc20(address: "0xa1d0E215a23d7030842FC67cE582a6aFa3CCaB83")),
        Coin(id: "YFIM",      title: "yfi.mobi",                          code: "YFIM",    decimal: 18, type: .erc20(address: "0x2e2f3246b6c65ccc4239c9ee556ec143a7e5de2c")),
        Coin(id: "ZAI",       title: "Zero Collateral Dai",               code: "ZAI",     decimal: 18, type: .erc20(address: "0x9d1233cc46795E94029fDA81aAaDc1455D510f15")),


    ]

    private let testNetCoins = [
        Coin(id: "BTC",       title: "Bitcoin",                       code: "BTC",     decimal: 8,  type: .bitcoin),
        Coin(id: "LTC",       title: "Litecoin",                      code: "LTC",     decimal: 8,  type: .litecoin),
        ethereumCoin,
        Coin(id: "BCH",       title: "Bitcoin Cash",                  code: "BCH",     decimal: 8,  type: .bitcoinCash),
        Coin(id: "DASH",      title: "Dash",                          code: "DASH",    decimal: 8,  type: .dash),
        Coin(id: "BNB",       title: "Binance Chain",                 code: "BNB",     decimal: 8,  type: .binance(symbol: "BNB")),
        Coin(id: "ZEC",       title: "Zcash",                         code: "ZEC",     decimal: 8,  type: .zcash),
        Coin(id: "DAI",       title: "Dai",                           code: "DAI",     decimal: 18, type: .erc20(address: "0xad6d458402f60fd3bd25163575031acdce07538d")),
        Coin(id: "WEENUS",    title: "WEENUS",                        code: "WEENUS",  decimal: 18, type: .erc20(address: "0x101848D5C5bBca18E6b4431eEdF6B95E9ADF82FA")),
    ]

    let smartContractFees: [CoinType: Decimal] = [:]
    let minimumBalances: [CoinType: Decimal] = [.erc20(address: "0x039B5649A59967e3e936D7471f9c3700100Ee1ab"): 0.001]
    let minimumSpendableAmounts: [CoinType: Decimal] = [.erc20(address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF"): 0.001]
}
