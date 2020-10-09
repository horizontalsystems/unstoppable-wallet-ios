import Foundation

class AppConfigProvider: IAppConfigProvider {
    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://unstoppable.money"
    let appGitHubLink = "https://github.com/horizontalsystems/unstoppable-wallet-ios"
    let reportEmail = "hsdao@protonmail.ch"
    let telegramWalletHelpAccount = "UnstoppableWallet"
    var guidesIndexUrl: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "GuidesIndexUrl") as! String))!
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

    func defaultWords(count: Int) -> [String] {
        guard let wordsString = Bundle.main.object(forInfoDictionaryKey: "DefaultWords\(count)") as? String else {
            return []
        }

        return wordsString.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
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

    var pnsUrl: String {
        let development = "http://pns-dev.horizontalsystems.xyz/api/v1/"
        let production = "http://pns.horizontalsystems.xyz/api/v1/"

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
        ]
    }

    let defaultCoins = [
        Coin(id: "BTC",       title: "Bitcoin",               code: "BTC",     decimal: 8,  type: .bitcoin),
        Coin(id: "LTC",       title: "Litecoin",              code: "LTC",     decimal: 8,  type: .litecoin),
        ethereumCoin,
        Coin(id: "BCH",       title: "Bitcoin Cash",          code: "BCH",     decimal: 8,  type: .bitcoinCash),
        Coin(id: "DASH",      title: "Dash",                  code: "DASH",    decimal: 8,  type: .dash),
        Coin(id: "BNB",       title: "Binance Chain",         code: "BNB",     decimal: 8,  type: .binance(symbol: "BNB")),
        Coin(id: "EOS",       title: "EOS",                   code: "EOS",     decimal: 4,  type: .eos(token: "eosio.token", symbol: "EOS")),
        Coin(id: "ZRX",       title: "0x Protocol",           code: "ZRX",     decimal: 18, type: CoinType(erc20Address: "0xE41d2489571d322189246DaFA5ebDe1F4699F498")),
        Coin(id: "LEND",      title: "Aave",                  code: "LEND",    decimal: 18, type: CoinType(erc20Address: "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03")),
        Coin(id: "ELF",       title: "Aelf",                  code: "ELF",     decimal: 18, type: CoinType(erc20Address: "0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e")),
        Coin(id: "AKRO",      title: "Akropolis",             code: "AKRO",    decimal: 18, type: CoinType(erc20Address: "0x8ab7404063ec4dbcfd4598215992dc3f8ec853d7")),
        Coin(id: "AMPL",      title: "Ampleforth",            code: "AMPL",    decimal: 9,  type: CoinType(erc20Address: "0xd46ba6d942050d489dbd938a2c909a5d5039a161")),
        Coin(id: "ANKR",      title: "Ankr Network",          code: "ANKR",    decimal: 8,  type: .binance(symbol: "ANKR-E97")),
        Coin(id: "ANT",       title: "Aragon",                code: "ANT",     decimal: 18, type: CoinType(erc20Address: "0x960b236A07cf122663c4303350609A66A7B288C0")),
        Coin(id: "REP",       title: "Augur",                 code: "REP",     decimal: 18, type: CoinType(erc20Address: "0x1985365e9f78359a9B6AD760e32412f4a445E862")),
        Coin(id: "BAL",       title: "Balancer",              code: "BAL",     decimal: 18, type: CoinType(erc20Address: "0xba100000625a3754423978a60c9317c58a424e3D")),
        Coin(id: "BNT",       title: "Bancor",                code: "BNT",     decimal: 18, type: CoinType(erc20Address: "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C")),
        Coin(id: "BAT",       title: "Basic Attention Token", code: "BAT",     decimal: 18, type: CoinType(erc20Address: "0x0D8775F648430679A709E98d2b0Cb6250d2887EF")),
        Coin(id: "BNB-ERC20", title: "Binance ERC20",         code: "BNB",     decimal: 18, type: CoinType(erc20Address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")),
        Coin(id: "BUSD",      title: "Binance USD",           code: "BUSD",    decimal: 8,  type: .binance(symbol: "BUSD-BD1")),
        Coin(id: "BTCB",      title: "Bitcoin BEP2",          code: "BTCB",    decimal: 8,  type: .binance(symbol: "BTCB-1DE")),
        Coin(id: "CAS",       title: "Cashaa",                code: "CAS",     decimal: 8,  type: .binance(symbol: "CAS-167")),
        Coin(id: "LINK",      title: "Chainlink",             code: "LINK",    decimal: 18, type: CoinType(erc20Address: "0x514910771AF9Ca656af840dff83E8264EcF986CA")),
        Coin(id: "CVC",       title: "Civic",                 code: "CVC",     decimal: 8,  type: CoinType(erc20Address: "0x41e5560054824ea6b0732e656e3ad64e20e94e45")),
        Coin(id: "COMP",      title: "Compound",              code: "COMP",    decimal: 18, type: CoinType(erc20Address: "0xc00e94cb662c3520282e6f5717214004a7f26888")),
        Coin(id: "CRPT",      title: "Crypterium",            code: "CRPT",    decimal: 8,  type: .binance(symbol: "CRPT-8C9")),
        Coin(id: "CRO",       title: "Crypto.com Coin",       code: "CRO",     decimal: 8,  type: CoinType(erc20Address: "0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b")),
        Coin(id: "DAI",       title: "Dai",                   code: "DAI",     decimal: 18, type: CoinType(erc20Address: "0x6b175474e89094c44da98b954eedeac495271d0f")),
        Coin(id: "MANA",      title: "Decentraland",          code: "MANA",    decimal: 18, type: CoinType(erc20Address: "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942")),
        Coin(id: "DIA",       title: "DIA",                   code: "DIA",     decimal: 18, type: CoinType(erc20Address: "0x84ca8bc7997272c7cfb4d0cd3d55cd942b3c9419")),
        Coin(id: "DGD",       title: "DigixDAO",              code: "DGD",     decimal: 9,  type: CoinType(erc20Address: "0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A")),
        Coin(id: "DGX",       title: "Digix Gold Token",      code: "DGX",     decimal: 9,  type: CoinType(erc20Address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF", minimumSpendableAmount: 0.001)),
        Coin(id: "DNT",       title: "District0x",            code: "DNT",     decimal: 18, type: CoinType(erc20Address: "0x0abdace70d3790235af448c88547603b945604ea")),
        Coin(id: "DOS",       title: "DOS Network",           code: "DOS",     decimal: 8, type: .binance(symbol: "DOS-120")),
        Coin(id: "DOS-ERC20", title: "DOS Network",           code: "DOS",     decimal: 18, type: CoinType(erc20Address: "0x0A913beaD80F321E7Ac35285Ee10d9d922659cB7")),
        Coin(id: "ENJ",       title: "Enjin Coin",            code: "ENJ",     decimal: 18, type: CoinType(erc20Address: "0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c")),
        Coin(id: "EOSDT",     title: "EOSDT",                 code: "EOSDT",   decimal: 9,  type: .eos(token: "eosdtsttoken", symbol: "EOSDT")),
        Coin(id: "IQ",        title: "Everipedia",            code: "IQ",      decimal: 3,  type: .eos(token: "everipediaiq", symbol: "IQ")),
        Coin(id: "GUSD",      title: "Gemini Dollar",         code: "GUSD",    decimal: 2,  type: CoinType(erc20Address: "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd")),
        Coin(id: "GTO",       title: "Gifto",                 code: "GTO",     decimal: 8,  type: .binance(symbol: "GTO-908")),
        Coin(id: "GNT",       title: "Golem",                 code: "GNT",     decimal: 18, type: CoinType(erc20Address: "0xa74476443119A942dE498590Fe1f2454d7D4aC0d")),
        Coin(id: "HOT",       title: "Holo",                  code: "HOT",     decimal: 18, type: CoinType(erc20Address: "0x6c6EE5e31d828De241282B9606C8e98Ea48526E2")),
        Coin(id: "HT",        title: "Huobi Token",           code: "HT",      decimal: 18, type: CoinType(erc20Address: "0x6f259637dcD74C767781E37Bc6133cd6A68aa161")),
        Coin(id: "IDXM",      title: "IDEX Membership",       code: "IDXM",    decimal: 8,  type: CoinType(erc20Address: "0xCc13Fc627EFfd6E35D2D2706Ea3C4D7396c610ea")),
        Coin(id: "IDEX",      title: "IDEX",                  code: "IDEX",    decimal: 18, type: CoinType(erc20Address: "0xB705268213D593B8FD88d3FDEFF93AFF5CbDcfAE")),
        Coin(id: "KCS",       title: "KuCoin Shares",         code: "KCS",     decimal: 6,  type: CoinType(erc20Address: "0x039B5649A59967e3e936D7471f9c3700100Ee1ab", minimumRequiredBalance: 0.001)),
        Coin(id: "KNC",       title: "Kyber Network Crystal", code: "KNC",     decimal: 18, type: CoinType(erc20Address: "0xdd974D5C2e2928deA5F71b9825b8b646686BD200")),
        Coin(id: "LOOM",      title: "Loom Network",          code: "LOOM",    decimal: 18, type: CoinType(erc20Address: "0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0")),
        Coin(id: "LRC",       title: "Loopring",              code: "LRC",     decimal: 18, type: CoinType(erc20Address: "0xEF68e7C694F40c8202821eDF525dE3782458639f")),
        Coin(id: "MKR",       title: "Maker",                 code: "MKR",     decimal: 18, type: CoinType(erc20Address: "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2")),
        Coin(id: "MCO",       title: "MCO",                   code: "MCO",     decimal: 8,  type: CoinType(erc20Address: "0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d")),
        Coin(id: "MEETONE",   title: "MEET.ONE",              code: "MEETONE", decimal: 4,  type: .eos(token: "eosiomeetone", symbol: "MEETONE")),
        Coin(id: "MITH",      title: "Mithril",               code: "MITH",    decimal: 18, type: CoinType(erc20Address: "0x3893b9422Cd5D70a81eDeFfe3d5A1c6A978310BB")),
        Coin(id: "TKN",       title: "Monolith",              code: "TKN",      decimal: 8, type: CoinType(erc20Address: "0xaaaf91d9b90df800df4f55c205fd6989c977e73a")),
        Coin(id: "NUT",       title: "Native Utility Token",  code: "NUT",     decimal: 9,  type: .eos(token: "eosdtnutoken", symbol: "NUT")),
        Coin(id: "NDX",       title: "Newdex",                code: "NDX",     decimal: 4,  type: .eos(token: "newdexissuer", symbol: "NDX")),
        Coin(id: "NEXO",      title: "Nexo",                  code: "NEXO",    decimal: 18, type: CoinType(erc20Address: "0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206")),
        Coin(id: "OMG",       title: "OmiseGO",               code: "OMG",     decimal: 18, type: CoinType(erc20Address: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07")),
        Coin(id: "ORBS",      title: "Orbs",                  code: "ORBS",    decimal: 18, type: CoinType(erc20Address: "0xff56Cc6b1E6dEd347aA0B7676C85AB0B3D08B0FA")),
        Coin(id: "OXT",       title: "Orchid",                code: "OXT",     decimal: 18, type: CoinType(erc20Address: "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb")),
        Coin(id: "PAR",       title: "Parachute",             code: "PAR",     decimal: 18, type: CoinType(erc20Address: "0x1beef31946fbbb40b877a72e4ae04a8d1a5cee06")),
        Coin(id: "PAX",       title: "Paxos Standard",        code: "PAX",     decimal: 18, type: CoinType(erc20Address: "0x8E870D67F660D95d5be530380D0eC0bd388289E1")),
        Coin(id: "PAXG",      title: "PAX Gold",              code: "PAXG",    decimal: 18, type: CoinType(erc20Address: "0x45804880De22913dAFE09f4980848ECE6EcbAf78")),
        Coin(id: "PTI",       title: "Paytomat",              code: "PTI",     decimal: 4,  type: .eos(token: "ptitokenhome", symbol: "PTI")),
        Coin(id: "POLY",      title: "Polymath",              code: "POLY",    decimal: 18, type: CoinType(erc20Address: "0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC")),
        Coin(id: "PPT",       title: "Populous",              code: "PPT",     decimal: 8,  type: CoinType(erc20Address: "0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a")),
        Coin(id: "PGL",       title: "Prospectors Gold",      code: "PGL",     decimal: 4,  type: .eos(token: "prospectorsg", symbol: "PGL")),
        Coin(id: "NPXS",      title: "Pundi X",               code: "NPXS",    decimal: 18, type: CoinType(erc20Address: "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3")),
        Coin(id: "REN",       title: "Ren",                   code: "REN",     decimal: 18, type: CoinType(erc20Address: "0x408e41876cccdc0f92210600ef50372656052a38")),
        Coin(id: "RENBTC",    title: "renBTC",                code: "rBTC",    decimal: 8,  type: CoinType(erc20Address: "0xeb4c2781e4eba804ce9a9803c67d0893436bb27d")),
        Coin(id: "RENBCH",    title: "renBCH",                code: "rBCH",    decimal: 8,  type: CoinType(erc20Address: "0x459086f2376525bdceba5bdda135e4e9d3fef5bf")),
        Coin(id: "RENZEC",    title: "renZEC",                code: "rZEC",    decimal: 8,  type: CoinType(erc20Address: "0x1c5db575e2ff833e46a2e9864c22f4b22e0b37c2")),
        Coin(id: "R",         title: "Revain",                code: "R",       decimal: 0,  type: CoinType(erc20Address: "0x48f775EFBE4F5EcE6e0DF2f7b5932dF56823B990")),
        Coin(id: "XRP",       title: "Ripple",                code: "XRP",     decimal: 8,  type: .binance(symbol: "XRP-BF2")),
        Coin(id: "SAI",       title: "Sai",                   code: "SAI",     decimal: 18, type: CoinType(erc20Address: "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359")),
        Coin(id: "SNX",       title: "Synthetix",             code: "SNX",     decimal: 18, type: CoinType(erc20Address: "0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F")),
        Coin(id: "EURS",      title: "STASIS EURO",           code: "EURS",    decimal: 2,  type: CoinType(erc20Address: "0xdB25f211AB05b1c97D595516F45794528a807ad8")),
        Coin(id: "SNT",       title: "Status",                code: "SNT",     decimal: 18, type: CoinType(erc20Address: "0x744d70FDBE2Ba4CF95131626614a1763DF805B9E")),
        Coin(id: "CHSB",      title: "SwissBorg",             code: "CHSB",    decimal: 8,  type: CoinType(erc20Address: "0xba9d4199fab4f26efe3551d490e3821486f135ba")),
        Coin(id: "USDT",      title: "Tether USD",            code: "USDT",    decimal: 6,  type: CoinType(erc20Address: "0xdAC17F958D2ee523a2206206994597C13D831ec7")),
        Coin(id: "TUSD",      title: "TrueUSD",               code: "TUSD",    decimal: 18, type: CoinType(erc20Address: "0x0000000000085d4780B73119b644AE5ecd22b376")),
        Coin(id: "SWAP",      title: "TrustSwap",             code: "SWAP",    decimal: 18, type: CoinType(erc20Address: "0xCC4304A31d09258b0029eA7FE63d032f52e44EFe")),
        Coin(id: "USDC",      title: "USD Coin",              code: "USDC",    decimal: 6,  type: CoinType(erc20Address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")),
        Coin(id: "WTC",       title: "Waltonchain",           code: "WTC",     decimal: 18, type: CoinType(erc20Address: "0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74")),
        Coin(id: "WBTC",      title: "Wrapped Bitcoin",       code: "WBTC",    decimal: 8,  type: CoinType(erc20Address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599")),
        Coin(id: "WETH",      title: "Wrapped Ethereum",      code: "WETH",    decimal: 18, type: CoinType(erc20Address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2")),
    ]

}
