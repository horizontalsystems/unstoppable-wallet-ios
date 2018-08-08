import Foundation

class MainNet: NetworkProtocol {
    let name = "livenet"
    let alias = "mainnet"
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

    let genesisCheckpoint = Checkpoint(height: 0, reversedHex: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f", timestamp: 1231006505, target: 0x1d00ffff)!
    let lastCheckpoint = Checkpoint(height: 463680, reversedHex: "000000000000000000431a2f4619afe62357cd16589b638bb638f2992058d88e", timestamp: 1493259601, target: 0x18021b3e)!
}
