import Foundation

struct ZcashNode: Equatable {
    let name: String
    let url: URL
}

extension ZcashNode {
    static let defaultNodes = [
        ZcashNode(name: "zec.rocks", url: URL(string: "https://zec.rocks:443")!),
        ZcashNode(name: "na.zec.rocks", url: URL(string: "https://na.zec.rocks:443")!),
        ZcashNode(name: "sa.zec.rocks", url: URL(string: "https://sa.zec.rocks:443")!),
        ZcashNode(name: "eu.zec.rocks", url: URL(string: "https://eu.zec.rocks:443")!),
        ZcashNode(name: "ap.zec.rocks", url: URL(string: "https://ap.zec.rocks:443")!),
        ZcashNode(name: "us.zec.stardust.rest", url: URL(string: "https://us.zec.stardust.rest:443")!),
        ZcashNode(name: "eu.zec.stardust.rest", url: URL(string: "https://eu.zec.stardust.rest:443")!),
        ZcashNode(name: "eu2.zec.stardust.rest", url: URL(string: "https://eu2.zec.stardust.rest:443")!),
        ZcashNode(name: "jp.zec.stardust.rest", url: URL(string: "https://jp.zec.stardust.rest:443")!),
    ]
}
