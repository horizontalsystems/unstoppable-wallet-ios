import Foundation

class GuidesManager {
}

extension GuidesManager: IGuidesManager {

    var guides: [Guide] {
        [
            Guide(
                    title: "Tether in Simple Terms",
                    date: Date(),
                    imageUrl: "https://raw.githubusercontent.com/horizontalsystems/blockchain-crypto-guides/master/token_guides/images/usdt-Main-l.png",
                    fileName: "tether"
            ),
            Guide(
                    title: "MakerDAO & DAI in Simple Terms",
                    date: Date(),
                    imageUrl: "https://raw.githubusercontent.com/horizontalsystems/blockchain-crypto-guides/master/token_guides/images/mkr-Main-l.png",
                    fileName: "maker"
            ),
            Guide(
                    title: "Bitcoin In Simple Terms",
                    date: Date(),
                    imageUrl: "",
                    fileName: "bitcoin"
            ),
            Guide(
                    title: "Ethereum in Simple Terms",
                    date: Date(),
                    imageUrl: "",
                    fileName: "ethereum"
            ),
            Guide(
                    title: "Blockchains Explained",
                    date: Date(),
                    imageUrl: "",
                    fileName: "1-cryptocurrencies"
            ),
            Guide(
                    title: "Wallets Explained",
                    date: Date(),
                    imageUrl: "",
                    fileName: "2-wallets-explained"
            ),
            Guide(
                    title: "Private Keys Explained",
                    date: Date(),
                    imageUrl: "",
                    fileName: "3-private-keys"
            ),
        ]
    }

}
