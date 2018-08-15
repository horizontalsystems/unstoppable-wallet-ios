import Foundation

protocol PeerGroupDelegate : class {
    func peerGroupDidConnect()
    func peerGroupDidDisconnect()
    func peerGroupDidReceive(headers: [BlockHeader])
    func peerGroupDidReceive(merkleBlock: MerkleBlockMessage)
    func peerGroupDidReceive(transaction: Transaction)
    func shouldRequest(inventoryItem: InventoryItem) -> Bool
    func transaction(forHash hash: Data) -> Transaction?
}
