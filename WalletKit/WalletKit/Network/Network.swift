//
//  Network.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/01/30.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public class Network {
    public static let mainnet: Network = Mainnet()
    public static let testnet: Network = Testnet()

    public var name: String { return "" }
    public var alias: String { return "" }
    var pubkeyhash: UInt8 { return 0 }
    var privatekey: UInt8 { return 0 }
    var scripthash: UInt8 { return 0 }
    var xpubkey: UInt32 { return 0 }
    var xprivkey: UInt32 { return 0 }
    var magic: UInt32 { return 0 }
    public var port: UInt32 { return 0 }
    public var dnsSeeds: [String] { return [] }
    var checkpoints: [Checkpoint] { return [] }
    var genesisBlock: Data { return Data() }

    fileprivate init() {}
}

extension Network : Equatable {
    public static func ==(lhs: Network, rhs: Network) -> Bool {
        return lhs.name == rhs.name
    }
}

public class Mainnet: Network {
    public override var name: String {
        return "livenet"
    }
    public override var alias: String {
        return "mainnet"
    }
    override var pubkeyhash: UInt8 {
        return 0x00
    }
    override var privatekey: UInt8 {
        return 0x80
    }
    override var scripthash: UInt8 {
        return 0x05
    }
    override var xpubkey: UInt32 {
        return 0x0488b21e
    }
    override var xprivkey: UInt32 {
        return 0x0488ade4
    }
    override var magic: UInt32 {
        return 0xf9beb4d9
    }
    public override var port: UInt32 {
        return 8333
    }
    public override var dnsSeeds: [String] {
        return [
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
    }
    /// blockchain checkpoints - these are also used as starting points for partial chain downloads, so they need to be at
    /// difficulty transition boundaries in order to verify the block difficulty at the immediately following transition
    override var checkpoints: [Checkpoint] {
        return [
            Checkpoint(height:      0, hash: Data(Data(hex: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")!.reversed()), timestamp: 1231006505, target: 0x1d00ffff),
            Checkpoint(height:  20160, hash: Data(Data(hex: "000000000f1aef56190aee63d33a373e6487132d522ff4cd98ccfc96566d461e")!.reversed()), timestamp: 1248481816, target: 0x1d00ffff),
            Checkpoint(height:  40320, hash: Data(Data(hex: "0000000045861e169b5a961b7034f8de9e98022e7a39100dde3ae3ea240d7245")!.reversed()), timestamp: 1266191579, target: 0x1c654657),
            Checkpoint(height:  60480, hash: Data(Data(hex: "000000000632e22ce73ed38f46d5b408ff1cff2cc9e10daaf437dfd655153837")!.reversed()), timestamp: 1276298786, target: 0x1c0eba64),
            Checkpoint(height:  80640, hash: Data(Data(hex: "0000000000307c80b87edf9f6a0697e2f01db67e518c8a4d6065d1d859a3a659")!.reversed()), timestamp: 1284861847, target: 0x1b4766ed),
            Checkpoint(height: 100800, hash: Data(Data(hex: "000000000000e383d43cc471c64a9a4a46794026989ef4ff9611d5acb704e47a")!.reversed()), timestamp: 1294031411, target: 0x1b0404cb),
            Checkpoint(height: 120960, hash: Data(Data(hex: "0000000000002c920cf7e4406b969ae9c807b5c4f271f490ca3de1b0770836fc")!.reversed()), timestamp: 1304131980, target: 0x1b0098fa),
            Checkpoint(height: 141120, hash: Data(Data(hex: "00000000000002d214e1af085eda0a780a8446698ab5c0128b6392e189886114")!.reversed()), timestamp: 1313451894, target: 0x1a094a86),
            Checkpoint(height: 161280, hash: Data(Data(hex: "00000000000005911fe26209de7ff510a8306475b75ceffd434b68dc31943b99")!.reversed()), timestamp: 1326047176, target: 0x1a0d69d7),
            Checkpoint(height: 181440, hash: Data(Data(hex: "00000000000000e527fc19df0992d58c12b98ef5a17544696bbba67812ef0e64")!.reversed()), timestamp: 1337883029, target: 0x1a0a8b5f),
            Checkpoint(height: 201600, hash: Data(Data(hex: "00000000000003a5e28bef30ad31f1f9be706e91ae9dda54179a95c9f9cd9ad0")!.reversed()), timestamp: 1349226660, target: 0x1a057e08),
            Checkpoint(height: 221760, hash: Data(Data(hex: "00000000000000fc85dd77ea5ed6020f9e333589392560b40908d3264bd1f401")!.reversed()), timestamp: 1361148470, target: 0x1a04985c),
            Checkpoint(height: 241920, hash: Data(Data(hex: "00000000000000b79f259ad14635739aaf0cc48875874b6aeecc7308267b50fa")!.reversed()), timestamp: 1371418654, target: 0x1a00de15),
            Checkpoint(height: 262080, hash: Data(Data(hex: "000000000000000aa77be1c33deac6b8d3b7b0757d02ce72fffddc768235d0e2")!.reversed()), timestamp: 1381070552, target: 0x1916b0ca),
            Checkpoint(height: 282240, hash: Data(Data(hex: "0000000000000000ef9ee7529607286669763763e0c46acfdefd8a2306de5ca8")!.reversed()), timestamp: 1390570126, target: 0x1901f52c),
            Checkpoint(height: 302400, hash: Data(Data(hex: "0000000000000000472132c4daaf358acaf461ff1c3e96577a74e5ebf91bb170")!.reversed()), timestamp: 1400928750, target: 0x18692842),
            Checkpoint(height: 322560, hash: Data(Data(hex: "000000000000000002df2dd9d4fe0578392e519610e341dd09025469f101cfa1")!.reversed()), timestamp: 1411680080, target: 0x181fb893),
            Checkpoint(height: 342720, hash: Data(Data(hex: "00000000000000000f9cfece8494800d3dcbf9583232825da640c8703bcd27e7")!.reversed()), timestamp: 1423496415, target: 0x1818bb87),
            Checkpoint(height: 362880, hash: Data(Data(hex: "000000000000000014898b8e6538392702ffb9450f904c80ebf9d82b519a77d5")!.reversed()), timestamp: 1435475246, target: 0x1816418e),
            Checkpoint(height: 383040, hash: Data(Data(hex: "00000000000000000a974fa1a3f84055ad5ef0b2f96328bc96310ce83da801c9")!.reversed()), timestamp: 1447236692, target: 0x1810b289),
            Checkpoint(height: 403200, hash: Data(Data(hex: "000000000000000000c4272a5c68b4f55e5af734e88ceab09abf73e9ac3b6d01")!.reversed()), timestamp: 1458292068, target: 0x1806a4c3),
            Checkpoint(height: 423360, hash: Data(Data(hex: "000000000000000001630546cde8482cc183708f076a5e4d6f51cd24518e8f85")!.reversed()), timestamp: 1470163842, target: 0x18057228),
            Checkpoint(height: 443520, hash: Data(Data(hex: "00000000000000000345d0c7890b2c81ab5139c6e83400e5bed00d23a1f8d239")!.reversed()), timestamp: 1481765313, target: 0x18038b85),
            Checkpoint(height: 463680, hash: Data(Data(hex: "000000000000000000431a2f4619afe62357cd16589b638bb638f2992058d88e")!.reversed()), timestamp: 1493259601, target: 0x18021b3e),
        ]
    }
    // These hashes are genesis blocks' ones
    override var genesisBlock: Data {
        return Data(Data(hex: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f")!.reversed())
    }

    fileprivate override init() {}
}

public class Testnet: Network {
    public override var name: String {
        return "testnet"
    }
    public override var alias: String {
        return "regtest"
    }
    override var pubkeyhash: UInt8 {
        return 0x6f
    }
    override var privatekey: UInt8 {
        return 0xef
    }
    override var scripthash: UInt8 {
        return 0xc4
    }
    override var xpubkey: UInt32 {
        return 0x043587cf
    }
    override var xprivkey: UInt32 {
        return 0x04358394
    }
    override var magic: UInt32 {
        return 0x0b110907
    }
    public override var port: UInt32 {
        return 18333
    }
    public override var dnsSeeds: [String] {
        return [
            "testnet-seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
            "testnet-seed.bluematt.me",              // Matt Corallo
            "testnet-seed.bitcoin.petertodd.org",    // Peter Todd
            "testnet-seed.bitcoin.schildbach.de",    // Andreas Schildbach
            "bitcoin-testnet.bloqseeds.net",         // Bloq
        ]
    }
    override var checkpoints: [Checkpoint] {
        return [
            Checkpoint(height:       0, hash: Data(Data(hex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943")!.reversed()), timestamp: 1376543922, target: 0x1d00ffff),
            Checkpoint(height:  100800, hash: Data(Data(hex: "0000000000a33112f86f3f7b0aa590cb4949b84c2d9c673e9e303257b3be9000")!.reversed()), timestamp: 1393813869, target: 0x1c00d907),
            Checkpoint(height:  201600, hash: Data(Data(hex: "0000000000376bb71314321c45de3015fe958543afcbada242a3b1b072498e38")!.reversed()), timestamp: 1413766239, target: 0x1b602ac0),
            Checkpoint(height:  302400, hash: Data(Data(hex: "0000000000001c93ebe0a7c33426e8edb9755505537ef9303a023f80be29d32d")!.reversed()), timestamp: 1431821666, target: 0x1a33605e),
            Checkpoint(height:  403200, hash: Data(Data(hex: "0000000000ef8b05da54711e2106907737741ac0278d59f358303c71d500f3c4")!.reversed()), timestamp: 1436951946, target: 0x1c02346c),
            Checkpoint(height:  504000, hash: Data(Data(hex: "0000000000005d105473c916cd9d16334f017368afea6bcee71629e0fcf2f4f5")!.reversed()), timestamp: 1447484641, target: 0x1b00ab86),
            Checkpoint(height:  604800, hash: Data(Data(hex: "00000000000008653c7e5c00c703c5a9d53b318837bb1b3586a3d060ce6fff2e")!.reversed()), timestamp: 1455728685, target: 0x1a092a20),
            Checkpoint(height:  705600, hash: Data(Data(hex: "00000000004ee3bc2e2dd06c31f2d7a9c3e471ec0251924f59f222e5e9c37e12")!.reversed()), timestamp: 1462006183, target: 0x1c0ffff0),
            Checkpoint(height:  806400, hash: Data(Data(hex: "0000000000000faf114ff29df6dbac969c6b4a3b407cd790d3a12742b50c2398")!.reversed()), timestamp: 1469705562, target: 0x1a34e280),
            Checkpoint(height:  907200, hash: Data(Data(hex: "0000000000166938e6f172a21fe69fe335e33565539e74bf74eeb00d2022c226")!.reversed()), timestamp: 1476926743, target: 0x1c00ffff),
            Checkpoint(height: 1008000, hash: Data(Data(hex: "000000000000390aca616746a9456a0d64c1bd73661fd60a51b5bf1c92bae5a0")!.reversed()), timestamp: 1490751239, target: 0x1a52ccc0),
            Checkpoint(height: 1108800, hash: Data(Data(hex: "00000000000288d9a219419d0607fb67cc324d4b6d2945ca81eaa5e739fab81e")!.reversed()), timestamp: 1296688602, target: 0x1b09ecf0),
        ]
    }
    override var genesisBlock: Data {
        return Data(Data(hex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943")!.reversed())
    }

    fileprivate override init() {}
}

struct Checkpoint {
    let height: Int32
    let hash: Data
    let timestamp: UInt32
    let target: UInt32
}
