import Foundation

struct WalletConnectChain: Codable {
    let chainId: String
    let chainName: String?
    let rpcUrls: [String]?
    let iconUrls: [String]?
    let nativeCurrency: WalletConnectNativeCurrency?
    let blockExplorerUrls: [String]?
}

struct WalletConnectNativeCurrency: Codable {
    let name: String
    let symbol: String
    let decimals: Int
}
