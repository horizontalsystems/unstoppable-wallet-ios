import Foundation

protocol PeerGroupDelegate : class {
    func peerGroupDidConnect()
    func peerGroupDidDisconnect()

    func peerGroupDidReceive(headers: [BlockHeader])
    func peerGroupDidReceive(blockHeader: BlockHeader, withTransactions transactions: [Transaction])
    func peerGroupDidReceive(transaction: Transaction)

    func shouldRequest(inventoryItem: InventoryItem) -> Bool
    func inventoryItem(inventoryItem: InventoryItem) -> InventoryItem
    func transaction(forHash hash: Data) -> Transaction?
}
