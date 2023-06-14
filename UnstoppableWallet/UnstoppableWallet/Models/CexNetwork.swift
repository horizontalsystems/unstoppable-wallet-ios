import MarketKit

struct CexNetwork {
    let network: String
    let name: String
    let isDefault: Bool
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let blockchain: Blockchain?
}
