import BigInt
import Foundation
import MarketKit
import TronKit

// Orchestrates GasFree send: fetches account state, asks `GasFreeMessageBuilder` to assemble
// the TIP-712 message, signs via passkey, posts SubmitTransferRequest, hands archive to
// `GasFreeArchiver`. Single class, used per-send. Constructed by GasFreeSendHandler.instance(...).
class GasFreeSender {
    private let provider: GasFreeProvider
    private let smartAccountManager: SmartAccountManager
    private let passkeyManager: PasskeyManager
    private let archiver: GasFreeArchiver

    init(
        provider: GasFreeProvider,
        smartAccountManager: SmartAccountManager,
        passkeyManager: PasskeyManager
    ) {
        self.provider = provider
        self.smartAccountManager = smartAccountManager
        self.passkeyManager = passkeyManager
        archiver = GasFreeArchiver(smartAccountManager: smartAccountManager)
    }
}

extension GasFreeSender {
    func prepare(
        account: Account,
        token: TronKit.Address,
        value: BigUInt,
        receiver: TronKit.Address,
        baseToken: Token
    ) async throws -> PreparedGasFreeTransfer {
        guard let profile = try smartAccountManager.gasFreeProfile(accountId: account.id) else {
            throw SenderError.profileMissing
        }

        let info = try await provider.accountInfo(controllerAddress: profile.controllerAddress)
        guard let asset = info.assets.first(where: { $0.tokenAddress == token }) else {
            throw SenderError.tokenNotSupported
        }
        guard info.allowSubmit else {
            throw SenderError.submitNotAllowed
        }

        let breakdown = GasFreeMessageBuilder.feeBreakdown(asset: asset, isActive: info.active)
        let built = GasFreeMessageBuilder.makeMessage(
            token: token,
            serviceProvider: profile.providerId,
            controller: profile.controllerAddress,
            receiver: receiver,
            value: value,
            maxFee: breakdown.totalFee,
            nonce: info.nonce
        )

        return PreparedGasFreeTransfer(
            token: token,
            serviceProvider: profile.providerId,
            user: profile.controllerAddress,
            receiver: receiver,
            value: value,
            maxFee: breakdown.totalFee,
            deadline: built.deadline,
            version: GasFreeMessageBuilder.permitVersion,
            nonce: info.nonce,
            hashToSign: built.hash,
            feeBreakdown: breakdown,
            baseToken: baseToken
        )
    }

    func submit(account: Account, prepared: PreparedGasFreeTransfer) async throws -> String {
        guard case let .passkeyOwned(credentialID) = account.type else {
            throw SenderError.unsupportedAccount
        }

        let signature = try await GasFreeTip712Signer.signViaPasskey(
            credentialID: credentialID,
            messageHash: prepared.hashToSign,
            passkeyManager: passkeyManager
        )

        let request = GasFreeProvider.SubmitTransferRequest(
            token: prepared.token,
            serviceProvider: prepared.serviceProvider,
            user: prepared.user,
            receiver: prepared.receiver,
            value: prepared.value,
            maxFee: prepared.maxFee,
            deadline: prepared.deadline,
            version: Int(prepared.version),
            nonce: prepared.nonce,
            // Per gasfree.io spec §3.2: TronLink example removes the `0x` prefix
            // (`_signTypedData` … // remove 0x). Server rejects 0x-prefixed signatures.
            signatureHex: signature.hs.hex
        )

        let status = try await provider.submitTransfer(request)

        // Archive failure must not surface as a send failure: the transfer is already
        // accepted by the provider. Missing pending row only affects local history.
        do {
            try archiver.archive(account: account, prepared: prepared, status: status)
        } catch {
            print("[GasFreeSender] archive failed (transfer already submitted): traceId=\(status.id) error=\(error)")
        }

        return status.id
    }
}

extension GasFreeSender {
    enum SenderError: Error {
        case profileMissing
        case tokenNotSupported
        case submitNotAllowed
        case unsupportedAccount
    }
}
