import BigInt
import Eip20Kit
import EvmKit
import Foundation
import HsExtensions
import MarketKit

// Orchestrates AA send: reads on-chain state, calls Pimlico for gas + paymaster, signs via passkey,
// submits the UserOperation, archives a PendingUserOperationRecord.
//
// Single class, used per-send. Constructed by AaSendHandler.instance(...).
class AaSender {
    private let blockchainType: BlockchainType
    private let entryPoint: EvmKit.Address
    private let chainId: BigUInt
    private let evmKit: EvmKit.Kit
    private let pimlicoProvider: PimlicoProvider
    private let codeProvider: EvmCodeProvider
    private let passkeyManager: SmartAccountPasskeyManager
    private let smartAccountManager: SmartAccountManager

    init(
        blockchainType: BlockchainType,
        entryPoint: EvmKit.Address,
        chainId: BigUInt,
        evmKit: EvmKit.Kit,
        pimlicoProvider: PimlicoProvider,
        codeProvider: EvmCodeProvider,
        passkeyManager: SmartAccountPasskeyManager,
        smartAccountManager: SmartAccountManager
    ) {
        self.blockchainType = blockchainType
        self.entryPoint = entryPoint
        self.chainId = chainId
        self.evmKit = evmKit
        self.pimlicoProvider = pimlicoProvider
        self.codeProvider = codeProvider
        self.passkeyManager = passkeyManager
        self.smartAccountManager = smartAccountManager
    }
}

// MARK: - Public API

extension AaSender {
    /// Build, estimate gas, query paymaster, compute hash. The returned UserOp's
    /// `signature` field is empty — populated only by `submit(...)`.
    func prepare(
        account: Account,
        transactionData: TransactionData,
        tokenAddress: EvmKit.Address,
        baseToken: Token,
        gasPrices: PimlicoProvider.GasPrices.Tier? = nil,
        nonce: BigUInt? = nil
    ) async throws -> PreparedUserOp {
        guard let (publicKeyX, publicKeyY) = passkeyKeyPair(from: account) else {
            throw SenderError.notPasskeyAccount
        }

        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw SenderError.unsupportedChain
        }
        let sender = try Self.resolveSender(account: account, chain: chain)

        let isDeployed = try await codeProvider.isDeployed(address: sender)

        let resolvedNonce: BigUInt
        if let nonce {
            resolvedNonce = nonce
        } else {
            resolvedNonce = try await fetchNonce(sender: sender)
        }

        let resolvedGas: PimlicoProvider.GasPrices.Tier
        if let gasPrices {
            resolvedGas = gasPrices
        } else {
            resolvedGas = try await fetchStandardGasPrice()
        }

        let isFreshDeployment = !isDeployed
        let initCode = isFreshDeployment ? buildInitCode(publicKeyX: publicKeyX, publicKeyY: publicKeyY) : Data()

        // For fresh deployment we pre-query an ERC-20 paymaster stub to learn the paymaster
        // address, so our executeBatch's approve target is correct. Then we re-query under
        // verifyingPaymaster mode to get sponsored paymasterAndData.
        let paymasterAddress: EvmKit.Address?
        let callData: Data
        if isFreshDeployment {
            let probeUserOp = makeUserOp(
                sender: sender,
                nonce: resolvedNonce,
                initCode: initCode,
                callData: AccountFacet.encodeExecute(target: transactionData.to, value: transactionData.value, data: transactionData.input),
                gas: PimlicoProvider.GasEstimate(callGasLimit: 0, verificationGasLimit: 0, preVerificationGas: 0),
                gasPrices: resolvedGas,
                paymasterAndData: Data()
            )
            let erc20Stub = try await pimlicoProvider.getPaymasterStubData(userOp: probeUserOp, mode: .erc20(token: tokenAddress))
            paymasterAddress = try Self.extractPaymasterAddress(from: erc20Stub)

            // TODO: revisit approve amount strategy — currently infinity (memory: project_aa_paymaster_approval_todo).
            let eip20Kit = try Eip20Kit.Kit.instance(evmKit: evmKit, contractAddress: tokenAddress)
            let approveTxData = eip20Kit.approveTransactionData(
                spenderAddress: paymasterAddress!,
                amount: BigUInt(2).power(256) - 1
            )
            let approveCall = UserOperationCallData(target: tokenAddress, value: 0, data: approveTxData.input)
            let userCall = UserOperationCallData(target: transactionData.to, value: transactionData.value, data: transactionData.input)
            callData = AccountFacet.encodeExecuteBatch(calls: [approveCall, userCall])
        } else {
            paymasterAddress = nil
            callData = AccountFacet.encodeExecute(target: transactionData.to, value: transactionData.value, data: transactionData.input)
        }

        // Stub UserOp for paymaster + gas estimation: dummy signature gives realistic verification cost.
        let stubUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: PimlicoProvider.GasEstimate(callGasLimit: 0, verificationGasLimit: 0, preVerificationGas: 0),
            gasPrices: resolvedGas,
            paymasterAndData: Data(),
            signature: Secp256r1VerificationFacet.dummySignature()
        )

        let paymasterMode: PimlicoProvider.PaymasterMode = isFreshDeployment ? .verifying : .erc20(token: tokenAddress)
        let paymasterAndData = try await pimlicoProvider.getPaymasterStubData(userOp: stubUserOp, mode: paymasterMode)

        let estimateUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: PimlicoProvider.GasEstimate(callGasLimit: 0, verificationGasLimit: 0, preVerificationGas: 0),
            gasPrices: resolvedGas,
            paymasterAndData: paymasterAndData,
            signature: Secp256r1VerificationFacet.dummySignature()
        )
        let gasEstimate = try await pimlicoProvider.estimateUserOperationGas(userOp: estimateUserOp)

        let finalUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: gasEstimate,
            gasPrices: resolvedGas,
            paymasterAndData: paymasterAndData,
            signature: Data()
        )

        let userOpHash = PackedUserOperation.hash(userOp: finalUserOp, entryPoint: entryPoint, chainId: chainId)

        return PreparedUserOp(
            userOp: finalUserOp,
            userOpHash: userOpHash,
            isFreshDeployment: isFreshDeployment,
            gasEstimate: gasEstimate,
            gasPrices: resolvedGas,
            paymasterMode: paymasterMode,
            baseToken: baseToken
        )
    }

    /// Sign via passkey, submit via bundler, archive record. Returns userOpHash echoed by bundler.
    func submit(account: Account, prepared: PreparedUserOp) async throws -> Data {
        guard case let .passkeyOwned(credentialID, _, _) = account.type else {
            throw SenderError.notPasskeyAccount
        }

        let signatureBytes = try await PasskeyUserOpSigner.sign(
            userOpHash: prepared.userOpHash,
            credentialID: credentialID,
            passkeyManager: passkeyManager
        )

        let signedUserOp = UserOperation(
            sender: prepared.userOp.sender,
            nonce: prepared.userOp.nonce,
            initCode: prepared.userOp.initCode,
            callData: prepared.userOp.callData,
            callGasLimit: prepared.userOp.callGasLimit,
            verificationGasLimit: prepared.userOp.verificationGasLimit,
            preVerificationGas: prepared.userOp.preVerificationGas,
            maxFeePerGas: prepared.userOp.maxFeePerGas,
            maxPriorityFeePerGas: prepared.userOp.maxPriorityFeePerGas,
            paymasterAndData: prepared.userOp.paymasterAndData,
            signature: signatureBytes
        )

        let serverUserOpHash = try await pimlicoProvider.sendUserOperation(userOp: signedUserOp)

        try archive(account: account, userOpHash: serverUserOpHash)

        return serverUserOpHash
    }
}

// MARK: - Public types

extension AaSender {
    enum SenderError: Error {
        case notPasskeyAccount
        case unsupportedChain
        case profileMissing
        case deploymentMissing
        case malformedPaymasterStub
    }
}

struct PreparedUserOp {
    let userOp: UserOperation
    let userOpHash: Data
    let isFreshDeployment: Bool
    let gasEstimate: PimlicoProvider.GasEstimate
    let gasPrices: PimlicoProvider.GasPrices.Tier
    let paymasterMode: PimlicoProvider.PaymasterMode
    let baseToken: Token
}

// MARK: - Private helpers

private extension AaSender {
    static func resolveSender(account: Account, chain: Chain) throws -> EvmKit.Address {
        guard let address = account.type.evmAddress(chain: chain) else {
            throw SenderError.unsupportedChain
        }
        return address
    }

    func passkeyKeyPair(from account: Account) -> (publicKeyX: Data, publicKeyY: Data)? {
        guard case let .passkeyOwned(_, publicKeyX, publicKeyY) = account.type else {
            return nil
        }
        return (publicKeyX, publicKeyY)
    }

    func fetchNonce(sender: EvmKit.Address) async throws -> BigUInt {
        let calldata = EntryPointV06.encodeGetNonce(sender: sender, key: 0)
        let result = try await evmKit.fetchCall(contractAddress: entryPoint, data: calldata, defaultBlockParameter: .latest)
        return try EntryPointV06.decodeGetNonce(result)
    }

    func fetchStandardGasPrice() async throws -> PimlicoProvider.GasPrices.Tier {
        try await pimlicoProvider.getUserOperationGasPrice().standard
    }

    func buildInitCode(publicKeyX: Data, publicKeyY: Data) -> Data {
        let owner = (try? BarzFactory.encodeSecp256r1PublicKey(x: publicKeyX, y: publicKeyY)) ?? Data()
        return BarzFactory.buildInitCode(
            factory: ChainAddresses.barzFactory,
            verificationFacet: ChainAddresses.secp256r1VerificationFacet,
            owner: owner,
            salt: 0
        )
    }

    func makeUserOp(
        sender: EvmKit.Address,
        nonce: BigUInt,
        initCode: Data,
        callData: Data,
        gas: PimlicoProvider.GasEstimate,
        gasPrices: PimlicoProvider.GasPrices.Tier,
        paymasterAndData: Data,
        signature: Data = Data()
    ) -> UserOperation {
        UserOperation(
            sender: sender,
            nonce: nonce,
            initCode: initCode,
            callData: callData,
            callGasLimit: gas.callGasLimit,
            verificationGasLimit: gas.verificationGasLimit,
            preVerificationGas: gas.preVerificationGas,
            maxFeePerGas: gasPrices.maxFeePerGas,
            maxPriorityFeePerGas: gasPrices.maxPriorityFeePerGas,
            paymasterAndData: paymasterAndData,
            signature: signature
        )
    }

    static func extractPaymasterAddress(from paymasterAndData: Data) throws -> EvmKit.Address {
        // EntryPoint v0.6: paymasterAndData = paymasterAddress (20 bytes) | extraData
        guard paymasterAndData.count >= 20 else {
            throw SenderError.malformedPaymasterStub
        }
        return EvmKit.Address(raw: paymasterAndData.prefix(20))
    }

    func archive(account: Account, userOpHash: Data) throws {
        guard let profile = try smartAccountManager.profile(accountId: account.id) else {
            throw SenderError.profileMissing
        }
        guard let deployment = try smartAccountManager.deployment(profileId: profile.id, blockchainType: blockchainType) else {
            throw SenderError.deploymentMissing
        }

        let record = PendingUserOperationRecord(
            userOpHash: userOpHash.hs.hex,
            deploymentId: deployment.id,
            implementationVersion: profile.implementationVersion,
            txHash: nil,
            status: "pending",
            submittedAt: Date().timeIntervalSince1970,
            lastPolledAt: nil,
            bundlerUrl: pimlicoProvider.bundlerUrl
        )
        try smartAccountManager.savePendingOperation(record: record)
    }
}
