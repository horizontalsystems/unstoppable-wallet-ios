import Foundation

protocol PeerGroupDelegate : class {
    func peerGroupDidConnect()
    func peerGroupDidDisconnect()
    func peerGroupDidReceive(versionMessage message: VersionMessage)
    func peerGroupDidReceive(addressMessage message: AddressMessage)
    func peerGroupDidReceive(getDataMessage message: GetDataMessage)
    func peerGroupDidReceive(inventoryMessage message: InventoryMessage)
    func peerGroupDidReceive(headersMessage message: HeadersMessage)
    func peerGroupDidReceive(blockMessage message: BlockMessage)
    func peerGroupDidReceive(merkleBlockMessage message: MerkleBlockMessage)
    func peerGroupDidReceive(rejectMessage message: RejectMessage)
    func peerGroupDidReceive(transaction: Transaction)
}
