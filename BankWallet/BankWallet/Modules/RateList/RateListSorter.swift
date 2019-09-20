class RateListSorter: IRateListSorter {

    func smartSort(for coins: [Coin], featuredCoins: [Coin]) -> [Coin] {
        var sortedCoins: [Coin]
        if coins.isEmpty {
            sortedCoins = featuredCoins
        } else {
            sortedCoins = featuredCoins.filter { coins.contains($0) }
            sortedCoins.append(contentsOf: coins.filter { !featuredCoins.contains($0) }.sorted { $0.code < $1.code })
        }

        return sortedCoins
    }

}
