struct AddressItem {
    let coin: Coin
    let addressType: String?
    let address: String
}

extension AddressItem: Equatable {

    public static func ==(lhs: AddressItem, rhs: AddressItem) -> Bool {
        lhs.coin == rhs.coin && lhs.address == rhs.address
    }

}
