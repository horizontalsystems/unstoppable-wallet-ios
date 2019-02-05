struct AddressItem {
    let coin: Coin
    let address: String
}

extension AddressItem: Equatable {

    public static func ==(lhs: AddressItem, rhs: AddressItem) -> Bool {
        return lhs.coin == rhs.coin && lhs.address == rhs.address
    }

}
