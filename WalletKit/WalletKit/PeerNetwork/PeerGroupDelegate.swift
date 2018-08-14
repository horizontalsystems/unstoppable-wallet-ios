import Foundation

protocol PeerGroupDelegate : class {
    func peerGroupDidConnect()
    func peerGroupDidDisconnect()
//    func peerGroupDidReceive(versionMessage message: VersionMessage)
//    func peerGroupDidReceive(addressMessage message: AddressMessage)
    func peerGroupDidReceive(getDataMessage message: GetDataMessage, peer: Peer)
    func peerGroupDidReceive(inventoryMessage message: InventoryMessage, peer: Peer)
    func peerGroupDidReceive(headersMessage message: HeadersMessage, peer: Peer)
//    func peerGroupDidReceive(blockMessage message: BlockMessage, peer: Peer)
    func peerGroupDidReceive(merkleBlockMessage message: MerkleBlockMessage, peer: Peer)
//    func peerGroupDidReceive(rejectMessage message: RejectMessage, peer: Peer)
    func peerGroupDidReceive(transaction: Transaction, peer: Peer)
}
