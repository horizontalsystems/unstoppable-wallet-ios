class ManageCoinsInteractor {
    weak var delegate: IManageCoinsInteractorDelegate?

    init() {
    }

}

extension ManageCoinsInteractor: IManageCoinsInteractor {

    func loadCoins() {
        //todo
        let bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
        let bitcoinCash = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
        let ethereum = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
        let allCoins = [
            bitcoin,
            bitcoinCash,
            ethereum
        ]
        delegate?.didLoadCoins(all: allCoins, enabled: allCoins)
    }

    func save(enabledCoins: [Coin]) {

    }

}
