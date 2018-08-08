import Foundation

protocol NetworkProtocol: class {
    var name: String { get }
    var alias: String { get }
    var pubKeyHash: UInt8 { get }
    var privateKey: UInt8 { get }
    var scriptHash: UInt8 { get }
    var xPubKey: UInt32 { get }
    var xPrivKey: UInt32 { get }
    var magic: UInt32 { get }
    var port: UInt32 { get }
    var dnsSeeds: [String] { get }
    var genesisCheckpoint: Checkpoint { get }
    var lastCheckpoint: Checkpoint { get }
}
