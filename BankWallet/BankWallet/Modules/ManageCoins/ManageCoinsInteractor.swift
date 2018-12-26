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
        let some = Coin(title: "some", code: "som", type: .bitcoin)
        let some2 = Coin(title: "some2", code: "som2", type: .bitcoin)
        let allCoins = [
            bitcoin,
            bitcoinCash,
            ethereum,
            some,
            some2
        ]
        let enabledCoins = [
            bitcoin,
            ethereum
        ]
        delegate?.didLoadCoins(all: allCoins, enabled: enabledCoins)
    }

    func save(enabledCoins: [Coin]) {
        delegate?.didSaveCoins()
    }

}
