import Foundation
import MarketKit
import ZODLSwiftWalletSDK

/// A Zcash receiver as the server names it in `addressRules.unified.receivers` / `requiresOneOf`.
enum ZcashReceiver: String, Equatable {
    case orchard
    case sapling
    case transparent
}

/// Which kind of Zcash address a route takes for one of its addresses.
enum ZcashAddressKind: Equatable {
    case transparent
    case unified(receivers: [String], requiresOneOf: [String])
}

/// What to send as `sourceAddress` on a ZEC sell.
enum ZcashSourcePolicy: Equatable {
    /// No `source` rule: a transfer venue builds nothing from it, so nothing is sent.
    case omit
    /// `source.sameAsRefund`: the provider refunds to the sender, so the source IS the refund address.
    case sameAsRefund
    /// A source rule of its own kind.
    case own(ZcashAddressKind)
}

/// Why a typed ZEC recipient does not fit the route's destination rule.
enum ZcashRecipientMismatch: Error, Equatable {
    /// Not a Zcash address of any kind this app knows
    case unparseable
    /// A unified / Sapling / TEX address on a route that takes transparent ones only (TEX when the rule allows it)
    case shieldedOnTransparentRoute
    /// A transparent (or TEX) address on a route whose rule says `transparent: false`
    case transparentNotAccepted
    /// A unified address none of whose receivers the route requires (`requiresOneOf`)
    case missingRequiredReceiver
    /// A Sapling address: no route names it in `addressRules`
    case saplingNotAccepted
}

/// The one place that reads a route's `addressRules` into address kinds. The rule for every address
/// alike: `unified` present -> a unified address built from `receivers`; otherwise transparent. No
/// rules at all (a non-ZEC route) means transparent everywhere, which every route takes; the server
/// validates at preview and the provider re-previews once on a `400`.
enum USwapZcashAddressPolicy {
    typealias Rules = USwapMultiSwapApi.ZcashAddressRules

    static let fallbackReceivers: [ZcashReceiver] = [.orchard, .sapling]
    static let vaultExecutionType = "thorchain_deposit"

    /// The buy-side kind. A vault deposit (`thorchain_deposit`) sold from a chain whose memo rides an
    /// OP_RETURN output cannot name a unified address in that memo, so the destination is forced to
    /// transparent whatever the rule recommends; every such route takes a transparent address.
    static func destinationKind(rules: Rules?, sellBlockchainType: BlockchainType, executionType: String?) -> ZcashAddressKind {
        if forcesTransparentDestination(sellBlockchainType: sellBlockchainType, executionType: executionType) {
            return .transparent
        }

        return kind(rule: rules?.destination)
    }

    /// Whether the destination rule takes a `tex1…` (ZIP-320) address too.
    static func destinationAcceptsTex(rules: Rules?) -> Bool {
        rules?.destination?.tex ?? false
    }

    /// Whether a transparent (`t1…` / `t3…`) destination is taken: the rule's `transparent` flag (absent
    /// reads as true), always true where the OP_RETURN memo guard forces a transparent destination.
    static func destinationAcceptsTransparent(rules: Rules?, sellBlockchainType: BlockchainType, executionType: String?) -> Bool {
        if forcesTransparentDestination(sellBlockchainType: sellBlockchainType, executionType: executionType) {
            return true
        }

        return rules?.destination?.transparent ?? true
    }

    static func refundKind(rules: Rules?) -> ZcashAddressKind {
        kind(rule: rules?.refund)
    }

    static func sourcePolicy(rules: Rules?) -> ZcashSourcePolicy {
        guard let source = rules?.source else {
            return .omit
        }

        if source.sameAsRefund {
            return .sameAsRefund
        }

        return .own(kind(rule: source))
    }

    /// The receivers to build the unified address from: the rule's `receivers` (orchard / sapling /
    /// transparent, unknown names dropped), completed with one of `requiresOneOf` when none of them is
    /// present, and `[.orchard, .sapling]` when the rule names nothing usable.
    static func receiversToBuild(_ unified: Rules.Unified) -> [ZcashReceiver] {
        var receivers = unified.receivers.compactMap { ZcashReceiver(rawValue: $0.lowercased()) }
        let required = unified.requiresOneOf.compactMap { ZcashReceiver(rawValue: $0.lowercased()) }

        if !required.isEmpty, !receivers.contains(where: required.contains), let first = required.first {
            receivers.append(first)
        }

        return receivers.isEmpty ? fallbackReceivers : receivers
    }

    static func receiversToBuild(kind: ZcashAddressKind) -> [ZcashReceiver] {
        switch kind {
        case .transparent:
            return []
        case let .unified(receivers, requiresOneOf):
            return receiversToBuild(Rules.Unified(receivers: receivers, requiresOneOf: requiresOneOf))
        }
    }

    /// What the recipient field accepts, as close to `validateRecipient` as the parser can express:
    /// transparent only for a transparent rule; shielded only for a unified rule that refuses transparent
    /// (`transparent: false`); anything otherwise. The parser cannot tell a Sapling address from a unified
    /// one, so `validateRecipient` stays the final client gate for that (and for `requiresOneOf`).
    static func recipientParserFilter(kind: ZcashAddressKind, acceptsTransparent: Bool) -> AddressParserFactory.ParserFilter? {
        switch kind {
        case .transparent: return .zCashTransparentOnly
        case .unified: return acceptsTransparent ? nil : .zCashTypes(.shielded)
        }
    }

    /// Checks a typed ZEC recipient against the route's destination rule before it is previewed:
    /// a transparent rule takes `t1…` / `t3…` (and `tex1…` when the rule allows it); a unified rule takes
    /// a unified address carrying one of `requiresOneOf` (when the SDK can read its receivers) or a
    /// transparent address; `transparent: false` refuses transparent and TEX addresses. A Sapling
    /// address fits no rule.
    static func validateRecipient(
        _ address: String,
        kind: ZcashAddressKind,
        acceptsTex: Bool,
        acceptsTransparent: Bool,
        network: NetworkType = ZcashAdapter.networkType
    ) throws {
        guard let recipient = try? Recipient(address, network: network) else {
            throw ZcashRecipientMismatch.unparseable
        }

        switch (recipient, kind) {
        case (.transparent, _):
            guard acceptsTransparent else {
                throw ZcashRecipientMismatch.transparentNotAccepted
            }
        case (.tex, _):
            guard acceptsTransparent else {
                throw ZcashRecipientMismatch.transparentNotAccepted
            }
            guard acceptsTex else {
                throw ZcashRecipientMismatch.shieldedOnTransparentRoute
            }
        case (.sapling, .transparent), (.unified, .transparent):
            throw ZcashRecipientMismatch.shieldedOnTransparentRoute
        case (.sapling, .unified):
            throw ZcashRecipientMismatch.saplingNotAccepted
        case let (.unified(unifiedAddress), .unified(_, requiresOneOf)):
            let required = requiresOneOf.compactMap { ZcashReceiver(rawValue: $0.lowercased()) }

            // No requirement, or receivers the SDK cannot read: the server's preview check decides.
            guard !required.isEmpty, let typecodes = try? unifiedAddress.availableReceiverTypecodes() else {
                return
            }

            let carried = Set(typecodes.compactMap(receiver(typecode:)))

            guard required.contains(where: carried.contains) else {
                throw ZcashRecipientMismatch.missingRequiredReceiver
            }
        }
    }

    /// Whether a resolved ZEC destination is a transparent (`t1…` / `t3…`) or TEX (`tex1…`) address: the
    /// only destinations a vault deposit from an OP_RETURN-memo chain can deliver to.
    static func isTransparentOrTex(_ address: String, network: NetworkType = ZcashAdapter.networkType) -> Bool {
        guard let recipient = try? Recipient(address, network: network) else {
            return false
        }

        switch recipient {
        case .transparent, .tex: return true
        case .sapling, .unified: return false
        }
    }

    private static func forcesTransparentDestination(sellBlockchainType: BlockchainType, executionType: String?) -> Bool {
        executionType == vaultExecutionType && sellBlockchainType.memoRidesOpReturn
    }

    private static func receiver(typecode: UnifiedAddress.ReceiverTypecodes) -> ZcashReceiver? {
        switch typecode {
        case .p2pkh, .p2sh: .transparent
        case .sapling: .sapling
        case .orchard: .orchard
        case .unknown: nil
        }
    }

    private static func kind(rule: Rules.Rule?) -> ZcashAddressKind {
        guard let unified = rule?.unified else {
            return .transparent
        }

        return .unified(receivers: unified.receivers, requiresOneOf: unified.requiresOneOf)
    }
}
