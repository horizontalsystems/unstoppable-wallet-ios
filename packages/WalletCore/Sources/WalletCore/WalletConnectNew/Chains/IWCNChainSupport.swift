import WalletConnectUtils

protocol IWCNChainSupport: AnyObject {
    var namespace: String { get }
    var supportedMethods: [String] { get }
    var supportedEvents: [String] { get }
    func supportedChains(account: Account) -> [WalletConnectUtils.Blockchain]
    func account(chain: WalletConnectUtils.Blockchain, account: Account) -> WalletConnectUtils.Account?
}
