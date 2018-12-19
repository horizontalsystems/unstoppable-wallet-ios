struct AddressItem {
    let address: String
    let coinCode: CoinCode
}

extension AddressItem: Equatable {

    public static func ==(lhs: AddressItem, rhs: AddressItem) -> Bool {
        return lhs.coinCode == rhs.coinCode && lhs.address == rhs.address
    }

}
