import Foundation

class MoneroNetworkSettingsViewModel {
    private let service: MoneroNetworkService

    private let nodeType: NodeType
    private let index: Int
    let isTrusted: Bool
    let nodeLabel: String

    private(set) var isTrustedNewValue: Bool?
    private var isTrustedAccepted = false

    init(service: MoneroNetworkService, nodeType: NodeType, index: Int) {
        self.service = service
        self.nodeType = nodeType
        self.index = index

        switch nodeType {
        case .predefined:
            let item = service.state.defaultItems[index]
            isTrusted = item.node.node.isTrusted
            nodeLabel = item.node.name
        case .custom:
            let item = service.state.customItems[index]
            isTrusted = item.node.node.isTrusted
            nodeLabel = item.node.name
        }
    }
}

extension MoneroNetworkSettingsViewModel {
    func onToggleIsTrusted(isOn: Bool) {
        isTrustedNewValue = isOn
    }

    func onTapSettingsDone() {
        isTrustedAccepted = true
    }

    func setCurrent() {
        let resolvedIsTrusted = isTrustedAccepted ? isTrustedNewValue ?? isTrusted : isTrusted

        switch nodeType {
        case .predefined:
            service.setDefault(index: index, isTrusted: resolvedIsTrusted)
        case .custom:
            service.setCustom(index: index, isTrusted: resolvedIsTrusted)
        }
    }
}

extension MoneroNetworkSettingsViewModel {
    enum NodeType {
        case predefined, custom
    }
}
