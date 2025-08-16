import Foundation
import MoneroKit

class MoneroNode {
    let name: String
    let node: Node

    init(name: String, node: Node) {
        self.name = name
        self.node = node
    }
}

extension MoneroNode: Equatable {
    static func == (lhs: MoneroNode, rhs: MoneroNode) -> Bool {
        lhs.node.url == rhs.node.url
    }
}
