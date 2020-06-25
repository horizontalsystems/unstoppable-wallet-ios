import Foundation

class CoinInfoMap {

    static let data: [String: CoinInfo] = [
        "BTC": CoinInfo(supply: 21_000_000, startDate: "03/01/2009", website: "https://bitcoin.org/en"),
        "LTC": CoinInfo(supply: 84_000_000, startDate: "13/10/2011", website: "https://litecoin.com"),
        "ETH": CoinInfo(supply: nil,  startDate: "30/07/2015", website: "https://www.ethereum.org"),
        "BCH": CoinInfo(supply: 21_000_000, startDate: "01/08/2017", website: "https://www.bitcoincash.org"),
        "DASH": CoinInfo(supply: 18_900_000, startDate: "18/01/2014", website: "http://dash.org"),
        "BNB": CoinInfo(supply: 187_536_713, startDate: "27/06/2017", website: "https://www.binance.com"),
        "EOS":  CoinInfo(supply: 1_035_000_004, startDate: "26/06/2017", website: "https://eos.io"),
        "CVC": CoinInfo(supply: 1_000_000_000, startDate: "21/06/2017", website: "https://www.civic.com"),
        "DNT": CoinInfo(supply: 1_000_000_000, startDate: "08/08/2017", website: "https://district0x.io"),
        "ZRX": CoinInfo(supply: 1_000_000_000, startDate: "15/08/2017", website: "https://www.0xproject.com/#home"),
        "ELF": CoinInfo(supply: 880_000_000, startDate: "18/12/2017", website: "http://aelf.io"),
        "ANKR": CoinInfo(supply: 10_000_000_000, startDate: "21/02/2019", website: "https://www.ankr.com"),
        "ANT": CoinInfo(supply: 39_609_524, startDate: "05/05/2017", website: "https://aragon.one"),
        "BNT": CoinInfo(supply: 67_721_371, startDate: "13/02/2017", website: "https://bancor.network"),
        "BAT": CoinInfo(supply: 1_500_000_000, startDate: "31/05/2017", website: "https://basicattentiontoken.org"),
        "BUSD": CoinInfo(supply: 28_603_822, startDate: "10/09/2019", website: "https://www.paxos.com/busd"),
        "CAS": CoinInfo(supply: 1_000_000_000, startDate: "12/10/2017", website: "https://cashaa.com"),
        "CHSB": CoinInfo(supply: 1_000_000_000, startDate: "08/09/2017", website: "https://swissborg.com"),
        "LINK": CoinInfo(supply: 1_000_000_000, startDate: "19/09/2017", website: "https://link.smartcontract.com"),
        "CRPT":  CoinInfo(supply: 99_785_291, startDate: "28/09/2017", website: "https://crypterium.io"),
        "CRO": CoinInfo(supply: 100_000_000_000, startDate: "14/11/2019", website: "https://www.crypto.com/en/chain"),
        "MANA": CoinInfo(supply: 2_644_403_343, startDate: "08/08/2017", website: "https://decentraland.org"),
        "DGD": CoinInfo(supply: 2_000_000, startDate: "28/04/2016", website: "https://www.dgx.io"),
        "ENJ": CoinInfo(supply: 1_000_000_000, startDate: "24/07/2017", website: "https://enjincoin.io"),
        "IQ": CoinInfo(supply: 10_006_128_771, startDate: "14/07/2018", website: "https://everipedia.org"),
        "GTO": CoinInfo(supply: 1_000_000_000, startDate: "14/12/2017", website: "https://gifto.io"),
        "GNT": CoinInfo(supply: 1_000_000_000, startDate: "17/11/2016", website: "https://golem.network"),
        "HOT": CoinInfo(supply: 177_619_433_541, startDate: "16/01/2018", website: "https://thehydrofoundation.com"),
        "HT": CoinInfo(supply: 500_000_000, startDate: "22/01/2018", website: "https://www.huobi.pro"),
        "IDEX": CoinInfo(supply: 1_000_000_000, startDate: "28/09/2017", website: "https://auroradao.com"),
        "KCS": CoinInfo(supply: 176_863_551, startDate: "15/09/2017", website: "https://www.kucoin.com/#"),
        "LOOM": CoinInfo(supply: 1_000_000_000, startDate: "03/03/2018", website: "https://loomx.io"),
        "MKR": CoinInfo(supply: 1_000_000, startDate: "15/08/2015", website: nil),
        "MEETONE": CoinInfo(supply: 10_000_000_000, startDate: "05/05/2018", website: "https://meet.one"),
        "MITH": CoinInfo(supply: 1_000_000_000, startDate: "12/03/2018", website: "https://mith.io"),
        "NDX": CoinInfo(supply: 10_000_000_000, startDate: nil, website: nil),
        "NEXO": CoinInfo(supply: 1_000_000_000, startDate: "29/04/2018", website: "https://nexo.io"),
        "ORBS": CoinInfo(supply: 10_000_000_000, startDate: "14/03/2018", website: "https://www.orbs.com"),
        "OXT": CoinInfo(supply: 10_000_000_000, startDate: "03/12/2019", website: "https://www.orchid.com"),
        "PAXG": CoinInfo(supply: 2_410, startDate: "29/08/2019", website: "https://www.paxos.com/paxgold"),
        "PPT": CoinInfo(supply: 53_252_246, startDate: "12/04/2017", website: "https://populous.world"),
        "PTI": CoinInfo(supply: 3_600_000_000, startDate: "13/03/2018", website: "https://tokensale.paytomat.com"),
        "POLY": CoinInfo(supply: 1_000_000_000, startDate: "25/12/2017", website: "https://www.polymath.network"),
        "PGL": CoinInfo(supply: 220_000_000, startDate: "19/04/2017", website: "https://prospectors.io/en"),
        "NPXS": CoinInfo(supply: 259_810_708_833, startDate: "27/09/2017", website: "https://pundix.com"),
        "R": CoinInfo(supply: 1_000_000_000, startDate: "04/08/2017", website: "http://revain.org"),
        "SNT": CoinInfo(supply: 6_804_870_174, startDate: "20/06/2017", website: "https://status.im"),
        "SNX": CoinInfo(supply: 174_648_076, startDate: "07/01/2018", website: "https://www.synthetix.io"),
        "WTC": CoinInfo(supply: 70_000_000, startDate: "27/08/2017", website: "http://www.waltonchain.org")
    ]

}

struct CoinInfo {
    let supply: Decimal?
    let startDate: String?
    let website: String?
}
