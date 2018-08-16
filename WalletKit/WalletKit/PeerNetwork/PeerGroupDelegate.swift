import Foundation

protocol PeerGroupDelegate : class {
    func peerGroupDidConnect()
    func peerGroupDidDisconnect()

    func peerGroupDidReceive(headers: [BlockHeader])
    func peerGroupDidReceive(blockHeaderHash: Data, withTransactions transactions: [Transaction])
    func peerGroupDidReceive(transactions: [Transaction])

    func shouldRequest(inventoryItem: InventoryItem) -> Bool
    func transaction(forHash hash: Data) -> Transaction?
}
