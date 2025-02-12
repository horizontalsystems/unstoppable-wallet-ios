import MarketKit

enum AddressSecurityIssueType: CaseIterable, Identifiable {
    case phishing
    case sanctioned
    case blacklisted

    var id: Self {
        self
    }

    var checkTitle: String {
        switch self {
        case .phishing: return "send.address.phishing_check".localized
        case .sanctioned: return "send.address.sanction_check".localized
        case .blacklisted: return "send.address.blacklist_check".localized
        }
    }

    var clearInfo: InfoDescription {
        switch self {
        case .phishing: return .init(title: "send.address.phishing.clear.title".localized, description: "send.address.phishing.clear.description".localized)
        case .sanctioned: return .init(title: "send.address.blacklist.clear.title".localized, description: "send.address.blacklist.clear.description".localized)
        case .blacklisted: return .init(title: "send.address.blacklist.clear.title".localized, description: "send.address.blacklist.clear.description".localized)
        }
    }

    var preSendTitle: String {
        switch self {
        case .phishing: return "send.address.phishing.pre_send.title".localized
        case .sanctioned: return "send.address.sanction.pre_send.title".localized
        case .blacklisted: return "send.address.blacklist.pre_send.title".localized
        }
    }

    var preSendDescription: String {
        switch self {
        case .phishing: return "send.address.phishing.pre_send.description".localized
        case .sanctioned: return "send.address.sanction.pre_send.description".localized
        case .blacklisted: return "send.address.blacklist.pre_send.description".localized
        }
    }

    var caution: CautionNew {
        switch self {
        case .phishing: return CautionNew(title: "send.address.phishing.caution.title".localized, text: "send.address.phishing.caution.description".localized, type: .error)
        case .sanctioned: return CautionNew(title: "send.address.sanction.caution.title".localized, text: "send.address.sanction.caution.description".localized, type: .error)
        case .blacklisted: return CautionNew(title: "send.address.blacklist.caution.title".localized, text: "send.address.blacklist.caution.description".localized, type: .error)
        }
    }

    func supports(token: Token) -> Bool {
        switch self {
        case .phishing: return EvmBlockchainManager.blockchainTypes.contains(token.blockchainType)
        case .sanctioned: return true
        case .blacklisted: return HashDitAddressValidator.supportedBlockchainTypes.contains(token.blockchainType) || Eip20AddressValidator.supports(token: token)
        }
    }

    static func issueTypes(token: Token) -> [Self] {
        allCases.filter { $0.supports(token: token) }
    }
}

struct ResolvedAddress: Hashable {
    let address: String
    let issueTypes: [AddressSecurityIssueType]
}
