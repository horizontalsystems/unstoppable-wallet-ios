enum WCVerdictReason: Equatable {
    case tokenSwapCarriesNativeValue
    case swapRouterUnsupported(chain: String)
    case swapNotToCanonicalRouter
    case missingSigner
    case malformedSigner
    case signerNotApproved(chain: String)
    case chainNotInSession(chain: String)
    case originScam
    case originInvalid
    case typedDataDomainWithoutChain
    case typedDataDomainChainNotApproved(chainId: Int)
    case ethSignBlindHash
    case ethSignUnreadable
    case solanaMessageIsTransaction
    case solanaMessageUnreadable
    case permitUnlimitedAllowance(spender: String)

    var text: String {
        switch self {
        case .tokenSwapCarriesNativeValue: return "wallet_connect.verdict.token_swap_native_value".localized
        case let .swapRouterUnsupported(chain): return "wallet_connect.verdict.swap_router_unsupported".localized(chain)
        case .swapNotToCanonicalRouter: return "wallet_connect.verdict.swap_not_canonical_router".localized
        case .missingSigner: return "wallet_connect.verdict.missing_signer".localized
        case .malformedSigner: return "wallet_connect.verdict.malformed_signer".localized
        case let .signerNotApproved(chain): return "wallet_connect.verdict.signer_not_approved".localized(chain)
        case let .chainNotInSession(chain): return "wallet_connect.verdict.chain_not_in_session".localized(chain)
        case .originScam: return "wallet_connect.verdict.origin_scam".localized
        case .originInvalid: return "wallet_connect.verdict.origin_invalid".localized
        case .typedDataDomainWithoutChain: return "wallet_connect.verdict.typed_data_no_chain".localized
        case let .typedDataDomainChainNotApproved(chainId): return "wallet_connect.verdict.typed_data_chain_not_approved".localized(String(chainId))
        case .ethSignBlindHash: return "wallet_connect.verdict.eth_sign_blind_hash".localized
        case .ethSignUnreadable: return "wallet_connect.verdict.eth_sign_unreadable".localized
        case .solanaMessageIsTransaction: return "wallet_connect.verdict.solana_message_is_transaction".localized
        case .solanaMessageUnreadable: return "wallet_connect.verdict.solana_message_unreadable".localized
        case let .permitUnlimitedAllowance(spender): return "wallet_connect.verdict.permit_unlimited".localized(spender)
        }
    }
}
