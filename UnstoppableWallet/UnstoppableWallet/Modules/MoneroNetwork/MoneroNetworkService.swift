import Foundation
import MarketKit
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
        state = State(
            defaultItems: items(nodes: moneroNodeManager.defaultNodes(blockchainType: blockchain.type)),
            customItems: items(nodes: moneroNodeManager.customNodes(blockchainType: blockchain.type))
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

    func setCurrent(node: MoneroNode) {
        guard currentNode != node else {
            return
        }

        moneroNodeManager.saveCurrent(node: node, blockchainType: blockchain.type)

        syncState()
    }
}

extension MoneroNetworkService {
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func setDefault(index: Int) {
        let node = state.defaultItems[index].node
        stat(page: .blockchainSettingsMonero, event: .switchMoneroNode(chainUid: blockchain.uid, name: node.name))
        setCurrent(node: node)
    }

    func setCustom(index: Int) {
        stat(page: .blockchainSettingsMonero, event: .switchMoneroNode(chainUid: blockchain.uid, name: "custom"))
        setCurrent(node: state.customItems[index].node)
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
