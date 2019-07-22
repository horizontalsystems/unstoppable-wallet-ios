import Foundation

class AppConfigProvider: IAppConfigProvider {
    let ipfsId = "QmXTJZBMMRmBbPun6HFt3tmb3tfYF2usLPxFoacL7G5uMX"
    let ipfsGateways = [
        "https://ipfs-ext.horizontalsystems.xyz",
        "https://ipfs.io"
    ]

    let fiatDecimal: Int = 2
    let maxDecimal: Int = 8

    let reachabilityHost = "ipfs.horizontalsystems.xyz"

    var testMode: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "TestMode") as? String == "true"
    }

    var defaultWords: [String] {
        guard let wordsString = Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String else {
            return []
        }

        return wordsString.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var etherscanKey: String {
        return (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var disablePinLock: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "DisablePinLock") as? String == "true"
    }

    let currencies: [Currency] = [
        Currency(code: "USD", symbol: "\u{0024}"),
        Currency(code: "EUR", symbol: "\u{20AC}"),
        Currency(code: "GBP", symbol: "\u{00A3}"),
        Currency(code: "JPY", symbol: "\u{00A5}"),
        Currency(code: "AUD", symbol: "\u{20B3}"),
        Currency(code: "CAD", symbol: "\u{0024}"),
        Currency(code: "CHF", symbol: "\u{20A3}"),
        Currency(code: "CNY", symbol: "\u{00A5}"),
        Currency(code: "KRW", symbol: "\u{20A9}"),
        Currency(code: "RUB", symbol: "\u{20BD}"),
        Currency(code: "TRY", symbol: "\u{20BA}")
    ]

    var defaultCoinCodes: [CoinCode] {
        return ["BTC", "ETH"]
    }

    let coins = [
        Coin(title: "Bitcoin",               code: "BTC",     type: .bitcoin),
        Coin(title: "Bitcoin Cash",          code: "BCH",     type: .bitcoinCash),
        Coin(title: "Ethereum",              code: "ETH",     type: .ethereum),
        Coin(title: "Dash",                  code: "DASH",    type: .dash),
        Coin(title: "EOS",                   code: "EOS",     type: .eos(token: "eosio.token", symbol: "EOS")),
        Coin(title: "0x",                    code: "ZRX",     type: .erc20(address: "0xE41d2489571d322189246DaFA5ebDe1F4699F498", decimal: 18, fee: 0)),
        Coin(title: "Aelf",                  code: "ELF",     type: .erc20(address: "0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e", decimal: 18, fee: 0)),
        Coin(title: "Aurora DAO",            code: "AURA",    type: .erc20(address: "0xCdCFc0f66c522Fd086A1b725ea3c0Eeb9F9e8814", decimal: 18, fee: 0)),
        Coin(title: "Bancor",                code: "BNT",     type: .erc20(address: "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C", decimal: 18, fee: 0)),
        Coin(title: "Basic Attention Token", code: "BAT",     type: .erc20(address: "0x0D8775F648430679A709E98d2b0Cb6250d2887EF", decimal: 18, fee: 0)),
        Coin(title: "Binance Coin",          code: "BNB",     type: .erc20(address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52", decimal: 18, fee: 0)),
        Coin(title: "ChainLink",             code: "LINK",    type: .erc20(address: "0x514910771AF9Ca656af840dff83E8264EcF986CA", decimal: 18, fee: 0)),
        Coin(title: "Crypto.com",            code: "MCO",     type: .erc20(address: "0xB63B606Ac810a52cCa15e44bB630fd42D8d1d83d", decimal: 8,  fee: 0)),
        Coin(title: "Crypto.com Chain",      code: "CRO",     type: .erc20(address: "0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b", decimal: 8,  fee: 0)),
        Coin(title: "Dai",                   code: "DAI",     type: .erc20(address: "0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359", decimal: 18, fee: 0)),
        Coin(title: "Decentraland",          code: "MANA",    type: .erc20(address: "0x0F5D2fB29fb7d3CFeE444a200298f468908cC942", decimal: 18, fee: 0)),
        Coin(title: "Digix DAO",             code: "DGD",     type: .erc20(address: "0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A", decimal: 9,  fee: 0)),
        Coin(title: "Digix Gold",            code: "DGX",     type: .erc20(address: "0x4f3AfEC4E5a3F2A6a1A411DEF7D7dFe50eE057bF", decimal: 9,  fee: 0)),
        Coin(title: "Enjin Coin",            code: "ENJ",     type: .erc20(address: "0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c", decimal: 18, fee: 0)),
        Coin(title: "EOSDT",                 code: "EOSDT",   type: .eos(token: "eosdtsttoken", symbol: "EOSDT")),
        Coin(title: "Gemini Dollar",         code: "GUSD",    type: .erc20(address: "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd", decimal: 2,  fee: 0)),
        Coin(title: "Golem",                 code: "GNT",     type: .erc20(address: "0xa74476443119A942dE498590Fe1f2454d7D4aC0d", decimal: 18, fee: 0)),
        Coin(title: "Holo",                  code: "HOT",     type: .erc20(address: "0x6c6EE5e31d828De241282B9606C8e98Ea48526E2", decimal: 18, fee: 0)),
        Coin(title: "Huobi Token",           code: "HT",      type: .erc20(address: "0x6f259637dcD74C767781E37Bc6133cd6A68aa161", decimal: 18, fee: 0)),
        Coin(title: "IDEX Membership",       code: "IDXM",    type: .erc20(address: "0xCc13Fc627EFfd6E35D2D2706Ea3C4D7396c610ea", decimal: 8,  fee: 0)),
        Coin(title: "IDEX Token",            code: "IDEX",    type: .erc20(address: "0xB705268213D593B8FD88d3FDEFF93AFF5CbDcfAE", decimal: 18, fee: 0)),
        Coin(title: "IQ",                    code: "IQ",      type: .eos(token: "everipediaiq", symbol: "IQ")),
        Coin(title: "KuCoin Shares",         code: "KCS",     type: .erc20(address: "0x039B5649A59967e3e936D7471f9c3700100Ee1ab", decimal: 6,  fee: 0)),
        Coin(title: "Kyber Network",         code: "KNC",     type: .erc20(address: "0xdd974D5C2e2928deA5F71b9825b8b646686BD200", decimal: 18, fee: 0)),
        Coin(title: "Loom",                  code: "LOOM",    type: .erc20(address: "0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0", decimal: 18, fee: 0)),
        Coin(title: "Loopring",              code: "LRC",     type: .erc20(address: "0xEF68e7C694F40c8202821eDF525dE3782458639f", decimal: 18, fee: 0)),
        Coin(title: "Maker",                 code: "MKR",     type: .erc20(address: "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2", decimal: 18, fee: 0)),
        Coin(title: "MEETONE",               code: "MEETONE", type: .eos(token: "eosiomeetone", symbol: "MEETONE")),
        Coin(title: "Mithril",               code: "MITH",    type: .erc20(address: "0x3893b9422Cd5D70a81eDeFfe3d5A1c6A978310BB", decimal: 18, fee: 0)),
        Coin(title: "NDX",                   code: "NDX",     type: .eos(token: "newdexissuer", symbol: "NDX")),
        Coin(title: "Nexo",                  code: "NEXO",    type: .erc20(address: "0xB62132e35a6c13ee1EE0f84dC5d40bad8d815206", decimal: 18, fee: 0)),
        Coin(title: "NUT",                   code: "NUT",     type: .eos(token: "eosdtnutoken", symbol: "NUT")),
        Coin(title: "OmiseGO",               code: "OMG",     type: .erc20(address: "0xd26114cd6EE289AccF82350c8d8487fedB8A0C07", decimal: 18, fee: 0)),
        Coin(title: "Orbs",                  code: "ORBS",    type: .erc20(address: "0xff56Cc6b1E6dEd347aA0B7676C85AB0B3D08B0FA", decimal: 18, fee: 0)),
        Coin(title: "Paxos Standard",        code: "PAX",     type: .erc20(address: "0x8E870D67F660D95d5be530380D0eC0bd388289E1", decimal: 18, fee: 0)),
        Coin(title: "PGL",                   code: "PGL",     type: .eos(token: "prospectorsg", symbol: "PGL")),
        Coin(title: "Polymath",              code: "POLY",    type: .erc20(address: "0x9992eC3cF6A55b00978cdDF2b27BC6882d88D1eC", decimal: 18, fee: 0)),
        Coin(title: "Populous",              code: "PPT",     type: .erc20(address: "0xd4fa1460F537bb9085d22C7bcCB5DD450Ef28e3a", decimal: 8,  fee: 0)),
        Coin(title: "PTI",                   code: "PTI",     type: .eos(token: "ptitokenhome", symbol: "PTI")),
        Coin(title: "Pundi X",               code: "NPXS",    type: .erc20(address: "0xA15C7Ebe1f07CaF6bFF097D8a589fb8AC49Ae5B3", decimal: 18, fee: 0)),
        Coin(title: "Reputation (Augur)",    code: "REP",     type: .erc20(address: "0x1985365e9f78359a9B6AD760e32412f4a445E862", decimal: 18, fee: 0)),
        Coin(title: "Revain",                code: "R",       type: .erc20(address: "0x48f775EFBE4F5EcE6e0DF2f7b5932dF56823B990", decimal: 0,  fee: 0)),
        Coin(title: "STASIS EURS",           code: "EURS",    type: .erc20(address: "0xdB25f211AB05b1c97D595516F45794528a807ad8", decimal: 2,  fee: 0.5)),
        Coin(title: "Status",                code: "SNT",     type: .erc20(address: "0x744d70FDBE2Ba4CF95131626614a1763DF805B9E", decimal: 18, fee: 0)),
        Coin(title: "Tether USD",            code: "USDT",    type: .erc20(address: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimal: 6,  fee: 0)),
        Coin(title: "TrueUSD",               code: "TUSD",    type: .erc20(address: "0x0000000000085d4780B73119b644AE5ecd22b376", decimal: 18, fee: 0)),
        Coin(title: "USD Coin",              code: "USDC",    type: .erc20(address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", decimal: 6,  fee: 0)),
        Coin(title: "Walton",                code: "WTC",     type: .erc20(address: "0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74", decimal: 18, fee: 0)),
        Coin(title: "Wax Token",             code: "WAX",     type: .erc20(address: "0x39Bb259F66E1C59d5ABEF88375979b4D20D98022", decimal: 8,  fee: 0)),
        Coin(title: "Zilliqa",               code: "ZIL",     type: .erc20(address: "0x05f4a42e251f2d52b8ed15E9FEdAacFcEF1FAD27", decimal: 12, fee: 0)),
    ]

    let predefinedAccountTypes: [IPredefinedAccountType] = [
        Words12AccountType(),
        EosAccountType(),
        Words24AccountType(),
    ]

}
