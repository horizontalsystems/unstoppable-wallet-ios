struct AddressItem {
    let title: String
    let address: String
    let coinCode: CoinCode
}

extension AddressItem: Equatable {

    public static func ==(lhs: AddressItem, rhs: AddressItem) -> Bool {
        return lhs.title == rhs.title && lhs.address == rhs.address && lhs.coinCode == rhs.coinCode
    }

}
