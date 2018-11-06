struct AddressItem {
    let address: String
    let coin: Coin
}

extension AddressItem: Equatable {

    public static func ==(lhs: AddressItem, rhs: AddressItem) -> Bool {
        return lhs.coin == rhs.coin && lhs.address == rhs.address
    }

}
