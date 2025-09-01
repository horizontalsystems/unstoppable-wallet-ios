import Foundation
import MarketKit
import MoneroKit
import RxRelay
import RxSwift

class MoneroNetworkService {
    let blockchain: Blockchain
    private let moneroNodeManager: MoneroNodeManager
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .init(defaultItems: [], customItems: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(blockchain: Blockchain, moneroNodeManager: MoneroNodeManager) {
        self.blockchain = blockchain
        self.moneroNodeManager = moneroNodeManager

        subscribe(disposeBag, moneroNodeManager.nodesUpdatedObservable) { [weak self] _ in self?.syncState() }

        syncState()
    }

    private var currentNode: MoneroNode {
        moneroNodeManager.node(blockchainType: blockchain.type)
    }

    private func syncState() {
        let (defaultNodes, customNodes) = moneroNodeManager.defaultAndCustomNodes(blockchainType: blockchain.type)

        state = State(
            defaultItems: items(nodes: defaultNodes),
            customItems: items(nodes: customNodes)
        )
    }

    private func items(nodes: [MoneroNode]) -> [Item] {
        let currentNode = currentNode

        return nodes.map { node in
            Item(
                node: node,
                selected: node == currentNode
            )
        }
    }

    func setCurrent(node: MoneroNode, isTrusted: Bool) {
        let kitNode = MoneroKit.Node(url: node.node.url, isTrusted: isTrusted, login: node.node.login, password: node.node.password)
        let node = MoneroNode(name: node.name, node: kitNode)

        guard currentNode != node else {
            return
        }

        moneroNodeManager.setCurrent(node: node, blockchainType: blockchain.type)
        syncState()
    }
}

extension MoneroNetworkService {
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func setDefault(index: Int, isTrusted: Bool) {
        let node = state.defaultItems[index].node
        stat(page: .blockchainSettingsMonero, event: .switchMoneroNode(chainUid: blockchain.uid, name: node.name))
        setCurrent(node: node, isTrusted: isTrusted)
    }

    func setCustom(index: Int, isTrusted: Bool) {
        stat(page: .blockchainSettingsMonero, event: .switchMoneroNode(chainUid: blockchain.uid, name: "custom"))
        setCurrent(node: state.customItems[index].node, isTrusted: isTrusted)
    }

    func removeCustom(index: Int) {
        stat(page: .blockchainSettingsMonero, event: .deleteCustomMoneroNode(chainUid: blockchain.uid))
        moneroNodeManager.delete(node: state.customItems[index].node, blockchainType: blockchain.type)
    }
}

extension MoneroNetworkService {
    struct State {
        let defaultItems: [Item]
        let customItems: [Item]
    }

    struct Item {
        let node: MoneroNode
        let selected: Bool
    }
}
