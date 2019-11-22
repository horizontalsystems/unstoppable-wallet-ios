import Foundation

class AppConfigProvider: IAppConfigProvider {
    let ipfsId = "QmXTJZBMMRmBbPun6HFt3tmb3tfYF2usLPxFoacL7G5uMX"
    let ipfsGateways = [
        "https://ipfs-ext.horizontalsystems.xyz",
        "https://ipfs.io"
    ]

    let companyWebPageLink = "https://horizontalsystems.io"
    let appWebPageLink = "https://unstoppable.money"
    let reportEmail = "hsdao@protonmail.ch"
    let reportTelegramGroup = "unstoppable_wallet"

    let reachabilityHost = "ipfs.horizontalsystems.xyz"

    var testMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
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
        return (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var disablePinLock: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "DisablePinLock") as? String == "true"
    }

    let currencies: [Currency] = [
        Currency(code: "USD", symbol: "\u{0024}", decimal: 2),
        Currency(code: "EUR", symbol: "\u{20AC}", decimal: 2),
        Currency(code: "GBP", symbol: "\u{00A3}", decimal: 2),
        Currency(code: "JPY", symbol: "\u{00A5}", decimal: 2),
        Currency(code: "AUD", symbol: "\u{20B3}", decimal: 2),
        Currency(code: "CAD", symbol: "\u{0024}", decimal: 2),
        Currency(code: "CHF", symbol: "\u{20A3}", decimal: 2),
        Currency(code: "CNY", symbol: "\u{00A5}", decimal: 2),
        Currency(code: "KRW", symbol: "\u{20A9}", decimal: 2),
        Currency(code: "RUB", symbol: "\u{20BD}", decimal: 2),
        Currency(code: "TRY", symbol: "\u{20BA}", decimal: 2)
    ]

    var defaultCoinCodes: [CoinCode] {
        return ["BTC", "ETH"]
    }

    var featuredCoins: [Coin] {
        return [
            coins[0],
            coins[1],
            coins[2],
            coins[3],
            coins[4],
            coins[5],
        ]
    }

    let coins = [
        Coin(id: "BTC",       title: "Bitcoin",               code: "BTC",     decimal: 8,  type: .bitcoin),
        Coin(id: "ETH",       title: "Ethereum",              code: "ETH",     decimal: 18, type: .ethereum),
        Coin(id: "BCH",       title: "Bitcoin Cash",          code: "BCH",     decimal: 8,  type: .bitcoinCash),
        Coin(id: "DASH",      title: "Dash",                  code: "DASH",    decimal: 8,  type: .dash),
        Coin(id: "BNB",       title: "Binance DEX",           code: "BNB",     decimal: 8,  type: .binance(symbol: "BNB")),
        Coin(id: "EOS",       title: "EOS",                   code: "EOS",     decimal: 4,  type: .eos(token: "eosio.token", symbol: "EOS")),
        Coin(id: "ZRX",       title: "0x",                    code: "ZRX",     decimal: 18, type: CoinType(erc20Address: "0xE41d2489571d322189246DaFA5ebDe1F4699F498")),
        Coin(id: "ELF",       title: "Aelf",                  code: "ELF",     decimal: 18, type: CoinType(erc20Address: "0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e")),
        Coin(id: "ANKR",      title: "Ankr Network",          code: "ANKR",    decimal: 8,  type: .binance(symbol: "ANKR-E97")),
        Coin(id: "AURA",      title: "Aurora DAO",            code: "AURA",    decimal: 18, type: CoinType(erc20Address: "0xCdCFc0f66c522Fd086A1b725ea3c0Eeb9F9e8814")),
        Coin(id: "BNT",       title: "Bancor ERC20",          code: "BNT",     decimal: 18, type: CoinType(erc20Address: "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C")),
        Coin(id: "BAT",       title: "Basic Attention Token", code: "BAT",     decimal: 18, type: CoinType(erc20Address: "0x0D8775F648430679A709E98d2b0Cb6250d2887EF")),
        Coin(id: "BNB-ERC20", title: "Binance ERC20",         code: "BNB",     decimal: 18, type: CoinType(erc20Address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52")),
        Coin(id: "BUSD",      title: "Binance USD",           code: "BUSD",    decimal: 8,  type: .binance(symbol: "BUSD-BD1")),
        Coin(id: "BTCB",      title: "Bitcoin BEP2",          code: "BTCB",    decimal: 8,  type: .binance(symbol: "BTCB-1DE")),
        Coin(id: "CAS",       title: "Cashaa",                code: "CAS",     decimal: 8,  type: .binance(symbol: "CAS-167")),
        Coin(id: "LINK",      title: "ChainLink",             code: "LINK",    decimal: 18, type: CoinType(erc20Address: "0x514910771AF9Ca656af840dff83E8264EcF986CA")),
        Coin(id: "CRPT",      title: "Crypterium",            code: "CRPT",    decimal: 8,  type: .binance(symbol: "CRPT-8C9")),
        Coin(id: "MCO",       title: "Crypto.com",            code: "MCO",     decimal: 8,  type: CoinType(erc20Address: "0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d")),
        Coin(id: "CRO",       title: "Crypto.com Chain",      code: "CRO",     decimal: 8,  type: CoinType(erc20Address: "0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b")),
        Coin(id: "DAI",       title: "Dai",                   code: "DAI",     decimal: 18, type: CoinType(erc20Address: "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359")),
        Coin(id: "MANA",      title: "Decentraland",          code: "MANA",    decimal: 18, type: CoinType(erc20Address: "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942")),
        Coin(id: "DGD",       title: "Digix DAO",             code: "DGD",     decimal: 9,  type: CoinType(erc20Address: "0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A")),
        Coin(id: "DGX",       title: "Digix Gold",            code: "DGX",     decimal: 9,  type: CoinType(erc20Address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF", gasLimit: 300_000)),
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
        Coin(id: "KNC",       title: "Kyber Network",         code: "KNC",     decimal: 18, type: CoinType(erc20Address: "0xdd974D5C2e2928deA5F71b9825b8b646686BD200")),
        Coin(id: "LOOM",      title: "Loom",                  code: "LOOM",    decimal: 18, type: CoinType(erc20Address: "0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0")),
        Coin(id: "LRC",       title: "Loopring",              code: "LRC",     decimal: 18, type: CoinType(erc20Address: "0xEF68e7C694F40c8202821eDF525dE3782458639f")),
        Coin(id: "MKR",       title: "Maker",                 code: "MKR",     decimal: 18, type: CoinType(erc20Address: "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2")),
        Coin(id: "MEETONE",   title: "MEET.ONE",              code: "MEETONE", decimal: 4,  type: .eos(token: "eosiomeetone", symbol: "MEETONE")),
        Coin(id: "MITH",      title: "Mithril",               code: "MITH",    decimal: 18, type: CoinType(erc20Address: "0x3893b9422Cd5D70a81eDeFfe3d5A1c6A978310BB")),
        Coin(id: "NUT",       title: "Native Utility Token",  code: "NUT",     decimal: 9,  type: .eos(token: "eosdtnutoken", symbol: "NUT")),
        Coin(id: "NDX",       title: "Newdex",                code: "NDX",     decimal: 4,  type: .eos(token: "newdexissuer", symbol: "NDX")),
        Coin(id: "NEXO",      title: "Nexo",                  code: "NEXO",    decimal: 18, type: CoinType(erc20Address: "0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206")),
        Coin(id: "OMG",       title: "OmiseGO",               code: "OMG",     decimal: 18, type: CoinType(erc20Address: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07")),
        Coin(id: "ORBS",      title: "Orbs",                  code: "ORBS",    decimal: 18, type: CoinType(erc20Address: "0xff56Cc6b1E6dEd347aA0B7676C85AB0B3D08B0FA")),
        Coin(id: "PAX",       title: "Paxos Standard",        code: "PAX",     decimal: 18, type: CoinType(erc20Address: "0x8E870D67F660D95d5be530380D0eC0bd388289E1")),
        Coin(id: "PAXG",      title: "Paxos Gold",            code: "PAXG",    decimal: 18, type: CoinType(erc20Address: "0x45804880De22913dAFE09f4980848ECE6EcbAf78")),
        Coin(id: "PTI",       title: "Paytomat",              code: "PTI",     decimal: 4,  type: .eos(token: "ptitokenhome", symbol: "PTI")),
        Coin(id: "POLY",      title: "Polymath",              code: "POLY",    decimal: 18, type: CoinType(erc20Address: "0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC")),
        Coin(id: "PPT",       title: "Populous",              code: "PPT",     decimal: 8,  type: CoinType(erc20Address: "0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a")),
        Coin(id: "PGL",       title: "Prospectors Gold",      code: "PGL",     decimal: 4,  type: .eos(token: "prospectorsg", symbol: "PGL")),
        Coin(id: "NPXS",      title: "Pundi X",               code: "NPXS",    decimal: 18, type: CoinType(erc20Address: "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3")),
        Coin(id: "REP",       title: "Reputation (Augur)",    code: "REP",     decimal: 18, type: CoinType(erc20Address: "0x1985365e9f78359a9B6AD760e32412f4a445E862")),
        Coin(id: "R",         title: "Revain",                code: "R",       decimal: 0,  type: CoinType(erc20Address: "0x48f775EFBE4F5EcE6e0DF2f7b5932dF56823B990")),
        Coin(id: "XRP",       title: "Ripple",                code: "XRP",     decimal: 8,  type: .binance(symbol: "XRP-BF2")),
        Coin(id: "EURS",      title: "STASIS EURS",           code: "EURS",    decimal: 2,  type: CoinType(erc20Address: "0xdB25f211AB05b1c97D595516F45794528a807ad8", fee: 0.5)),
        Coin(id: "SNT",       title: "Status",                code: "SNT",     decimal: 18, type: CoinType(erc20Address: "0x744d70FDBE2Ba4CF95131626614a1763DF805B9E")),
        Coin(id: "USDT",      title: "Tether USD",            code: "USDT",    decimal: 6,  type: CoinType(erc20Address: "0xdAC17F958D2ee523a2206206994597C13D831ec7")),
        Coin(id: "TUSD",      title: "TrueUSD",               code: "TUSD",    decimal: 18, type: CoinType(erc20Address: "0x0000000000085d4780B73119b644AE5ecd22b376")),
        Coin(id: "USDC",      title: "USD Coin",              code: "USDC",    decimal: 6,  type: CoinType(erc20Address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")),
        Coin(id: "WTC",       title: "Walton",                code: "WTC",     decimal: 18, type: CoinType(erc20Address: "0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74")),
    ]

    let predefinedAccountTypes: [IPredefinedAccountType] = [
        UnstoppableAccountType(),
        EosAccountType(),
        BinanceAccountType(),
    ]

}
