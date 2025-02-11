import MarketKit

enum AddressSecurityIssueType: CaseIterable, Identifiable {
    case phishing
    case sanctioned

    var id: Self {
        self
    }

    var checkTitle: String {
        switch self {
        case .phishing: return "send.address.phishing_check".localized
        case .sanctioned: return "send.address.blacklist_check".localized
        }
    }

    var clearInfo: InfoDescription {
        switch self {
        case .phishing: return .init(title: "send.address.phishing.clear.title".localized, description: "send.address.phishing.clear.description".localized)
        case .sanctioned: return .init(title: "send.address.blacklist.clear.title".localized, description: "send.address.blacklist.clear.description".localized)
        }
    }

    var preSendTitle: String {
        switch self {
        case .phishing: return "send.address.phishing.pre_send.title".localized
        case .sanctioned: return "send.address.blacklist.pre_send.title".localized
        }
    }

    var preSendDescription: String {
        switch self {
        case .phishing: return "send.address.phishing.pre_send.description".localized
        case .sanctioned: return "send.address.blacklist.pre_send.description".localized
        }
    }

    var caution: CautionNew {
        switch self {
        case .phishing: return CautionNew(title: "send.address.phishing.caution.title".localized, text: "send.address.phishing.caution.description".localized, type: .error)
        case .sanctioned: return CautionNew(title: "send.address.blacklist.caution.title".localized, text: "send.address.blacklist.caution.description".localized, type: .error)
        }
    }

    func supports(blockchainType: BlockchainType) -> Bool {
        switch self {
        case .phishing: return EvmBlockchainManager.blockchainTypes.contains(blockchainType)
        case .sanctioned: return true
        }
    }

    static func issueTypes(blockchainType: BlockchainType) -> [Self] {
        allCases.filter { $0.supports(blockchainType: blockchainType) }
    }
}

struct ResolvedAddress: Hashable {
    let address: String
    let issueTypes: [AddressSecurityIssueType]
}
