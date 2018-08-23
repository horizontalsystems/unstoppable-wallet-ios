import Foundation

class MainNet: NetworkProtocol {
    let name = "mainnet"
    let pubKeyHash: UInt8 = 0x00
    let privateKey: UInt8 = 0x80
    let scriptHash: UInt8 = 0x05
    let xPubKey: UInt32 = 0x0488b21e
    let xPrivKey: UInt32 = 0x0488ade4
    let magic: UInt32 = 0xf9beb4d9
    let port: UInt32 = 8333

    let dnsSeeds = [
        "seed.bitcoin.sipa.be",         // Pieter Wuille
        "dnsseed.bluematt.me",          // Matt Corallo
        "dnsseed.bitcoin.dashjr.org",   // Luke Dashjr
        "seed.bitcoinstats.com",        // Chris Decker
        "seed.bitnodes.io",             // Addy Yeow
        "bitseed.xf2.org",              // Jeff Garzik
        "seed.bitcoin.jonasschnelli.ch",// Jonas Schnelli
        "bitcoin.bloqseeds.net",        // Bloq
        "seed.ob1.io",                  // OpenBazaar
    ]

    let genesisBlock = Block(
            withHeader: BlockHeader(
                    version: 1,
                    previousBlockHeaderReversedHex: "0000000000000000000000000000000000000000000000000000000000000000",
                    merkleRootReversedHex: "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
                    timestamp: 1231006505,
                    bits: 486604799,
                    nonce: 2083236893
            ),
            height: 0)

    let checkpointBlock = Block(
            withHeader: BlockHeader(
                    version: 536870912,
                    previousBlockHeaderReversedHex: "00000000000000000000943de85f4495f053ff55f27d135edc61c27990c2eec5",
                    merkleRootReversedHex: "167bf70981d49388d07881b1a448ff9b79cf2a32716e45c535345823d8cdd541",
                    timestamp: 1533980459,
                    bits: 388763047,
                    nonce: 1545867530
            ),
            height: 536256)

}
