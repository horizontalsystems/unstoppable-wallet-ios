import MarketKit

enum AddressSecurityIssueType: CaseIterable, Identifiable {
    case phishing
    case sanctioned

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .phishing: return "send.address.phishing_check".localized
        case .sanctioned: return "send.address.blacklist_check".localized
        }
    }

    var caution: CautionNew {
        switch self {
        case .phishing: return CautionNew(title: "send.address.phishing.title".localized, text: "send.address.phishing.description".localized, type: .error)
        case .sanctioned: return CautionNew(title: "send.address.blacklist.title".localized, text: "send.address.blacklist.description".localized, type: .error)
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
