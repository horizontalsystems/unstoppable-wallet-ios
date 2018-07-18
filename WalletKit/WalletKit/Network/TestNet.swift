import Foundation

class TestNet: NetworkProtocol {
    let name = "testnet"
    let alias = "regtest"
    let pubKeyHash: UInt8 = 0x6f
    let privateKey: UInt8 = 0xef
    let scriptHash: UInt8 = 0xc4
    let xPubKey: UInt32 = 0x043587cf
    let xPrivKey: UInt32 = 0x04358394
    let magic: UInt32 = 0x0b110907
    let port: UInt32 = 18333

    let dnsSeeds = [
        "testnet-seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
        "testnet-seed.bluematt.me",              // Matt Corallo
        "testnet-seed.bitcoin.petertodd.org",    // Peter Todd
        "testnet-seed.bitcoin.schildbach.de",    // Andreas Schildbach
        "bitcoin-testnet.bloqseeds.net",         // Bloq
    ]

    let genesisCheckpoint = Checkpoint(height: 0, reversedHex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943", timestamp: 1376543922, target: 0x1d00ffff)!
    let lastCheckpoint = Checkpoint(height: 1108800, reversedHex: "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e", timestamp: 1296688602, target: 0x1b09ecf0)!
}
