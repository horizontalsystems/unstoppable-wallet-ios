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
    private let simulateHandleOpProvider: SimulateHandleOpProvider
    private let passkeyManager: PasskeyManager
    private let smartAccountManager: SmartAccountManager
    private let decorator = EvmDecorator()

    init(
        blockchainType: BlockchainType,
        entryPoint: EvmKit.Address,
        chainId: BigUInt,
        evmKit: EvmKit.Kit,
        pimlicoProvider: PimlicoProvider,
        codeProvider: EvmCodeProvider,
        simulateHandleOpProvider: SimulateHandleOpProvider,
        passkeyManager: PasskeyManager,
        smartAccountManager: SmartAccountManager
    ) {
        self.blockchainType = blockchainType
        self.entryPoint = entryPoint
        self.chainId = chainId
        self.evmKit = evmKit
        self.pimlicoProvider = pimlicoProvider
        self.codeProvider = codeProvider
        self.simulateHandleOpProvider = simulateHandleOpProvider
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
        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw SenderError.unsupportedChain
        }
        let profile = try smartAccountProfile(account: account)
        let publicKeyX = profile.ownerPublicKeyX
        let publicKeyY = profile.ownerPublicKeyY
        let curve = profile.curve
        let sender = try profile.address(blockchainType: blockchainType)

        print("[AaSender] prepare → chain=\(blockchainType.uid) chainId=\(chain.id) sender=\(sender.eip55) token=\(tokenAddress.eip55)")
        print("[AaSender] tx → to=\(transactionData.to.eip55) value=\(transactionData.value) inputBytes=\(transactionData.input.count)")

        let isDeployed = try await codeProvider.isDeployed(address: sender)
        print("[AaSender] eth_getCode(\(sender.eip55)) → isDeployed=\(isDeployed)")

        let resolvedNonce: BigUInt
        if let nonce {
            resolvedNonce = nonce
            print("[AaSender] nonce → reused-from-settings \(resolvedNonce)")
        } else {
            resolvedNonce = try await fetchNonce(sender: sender)
            print("[AaSender] nonce → EntryPoint.getNonce(key:0)=\(resolvedNonce)")
        }

        let resolvedGas: PimlicoProvider.GasPrices.Tier
        if let gasPrices {
            resolvedGas = gasPrices
            print("[AaSender] gasPrices → reused-from-settings maxFeePerGas=\(resolvedGas.maxFeePerGas) maxPriorityFeePerGas=\(resolvedGas.maxPriorityFeePerGas)")
        } else {
            resolvedGas = try await fetchStandardGasPrice()
            print("[AaSender] gasPrices → pim_getUserOperationGasPrice.standard maxFeePerGas=\(resolvedGas.maxFeePerGas) (\(Self.gwei(resolvedGas.maxFeePerGas)) gwei) maxPriorityFeePerGas=\(resolvedGas.maxPriorityFeePerGas) (\(Self.gwei(resolvedGas.maxPriorityFeePerGas)) gwei)")
        }

        // Decide which UserOp shape to build via SendScenarioDetector. Three branches:
        //   .freshDeploy      — AA not yet deployed; initCode + executeBatch[approve, userTx]
        //   .approvedSend     — AA deployed, sendToken approved to paymaster; execute(userTx)
        //   .approveAndSend   — AA deployed, allowance below threshold; executeBatch[approve, userTx]
        // The third branch fixes the "sent token differs from deploy-approved token" pathology:
        // without it Pimlico ERC-20 paymaster reverts at validation -> retry blowup -> double-charge.
        let scenarioDetector = SendScenarioDetector(
            fetchPaymasterAddress: { token, _ in
                let probeUserOp = self.makeUserOp(
                    sender: sender,
                    nonce: resolvedNonce,
                    initCode: Data(),
                    callData: AccountFacet.encodeExecute(target: transactionData.to, value: transactionData.value, data: transactionData.input),
                    gas: PimlicoProvider.GasEstimate(callGasLimit: 0, verificationGasLimit: 0, preVerificationGas: 0),
                    gasPrices: resolvedGas,
                    paymasterAndData: Data()
                )
                let stub = try await self.pimlicoProvider.getPaymasterStubData(userOp: probeUserOp, mode: .erc20(token: token))
                return try Self.extractPaymasterAddress(from: stub)
            },
            fetchIsDeployed: { _, _ in isDeployed },
            fetchAllowance: { _, spender, token, _ in
                let eip20Kit = try Eip20Kit.Kit.instance(evmKit: self.evmKit, contractAddress: token)
                let allowanceString = try await eip20Kit.allowance(spenderAddress: spender, defaultBlockParameter: .latest)
                guard let allowance = BigUInt(allowanceString) else {
                    throw SenderError.malformedAllowance
                }
                return allowance
            }
        )

        let scenario = try await scenarioDetector.detect(
            accountAddress: sender,
            blockchainType: blockchainType,
            sendToken: tokenAddress
        )
        let stubPaymasterAddress = scenario.paymaster
        print("[AaSender] scenario=\(scenario) paymaster=\(stubPaymasterAddress.eip55)")

        let isFreshDeployment: Bool
        let initCode: Data
        let callData: Data
        let feeScenario: AaSendFeeBreakdown.Scenario
        switch scenario {
        case .freshDeploy:
            isFreshDeployment = true
            feeScenario = .freshDeploy
            initCode = buildInitCode(publicKeyX: publicKeyX, publicKeyY: publicKeyY, curve: curve)
            callData = try AccountFacet.encodeExecuteBatch(calls: [
                buildApproveCall(token: tokenAddress, spender: stubPaymasterAddress),
                buildUserCall(transactionData: transactionData),
            ])
        case .approvedSend:
            isFreshDeployment = false
            feeScenario = .approvedSend
            initCode = Data()
            callData = AccountFacet.encodeExecute(
                target: transactionData.to,
                value: transactionData.value,
                data: transactionData.input
            )
        case .approveAndSend:
            isFreshDeployment = false
            feeScenario = .approveAndSend
            initCode = Data()
            callData = try AccountFacet.encodeExecuteBatch(calls: [
                buildApproveCall(token: tokenAddress, spender: stubPaymasterAddress),
                buildUserCall(transactionData: transactionData),
            ])
        }
        print("[AaSender] initCode bytes=\(initCode.count) callData bytes=\(callData.count) curve=\(curve.rawValue)")

        // Stub UserOp for paymaster + gas estimation: dummy signature gives realistic verification cost.
        let unsignedStubUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: PimlicoProvider.GasEstimate(callGasLimit: 0, verificationGasLimit: 0, preVerificationGas: 0),
            gasPrices: resolvedGas,
            paymasterAndData: Data()
        )
        let stubUserOp = try withDummySignature(unsignedStubUserOp, curve: curve, chain: chain)

        let paymasterMode: PimlicoProvider.PaymasterMode = .erc20(token: tokenAddress)
        print("[AaSender] paymasterMode=erc20 (user-paid, Pimlico-balance fallback on postOp revert) fresh=\(isFreshDeployment) callData bytes=\(callData.count)")
        let paymasterAndData = try await pimlicoProvider.getPaymasterStubData(userOp: stubUserOp, mode: paymasterMode)
        print("[AaSender] pm_getPaymasterStubData → paymasterAndData bytes=\(paymasterAndData.count)")

        let unsignedEstimateUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: PimlicoProvider.GasEstimate(callGasLimit: 0, verificationGasLimit: 0, preVerificationGas: 0),
            gasPrices: resolvedGas,
            paymasterAndData: paymasterAndData
        )
        let estimateUserOp = try withDummySignature(unsignedEstimateUserOp, curve: curve, chain: chain)
        let gasEstimate = try await pimlicoProvider.estimateUserOperationGas(userOp: estimateUserOp)
        let bufferedGasEstimate = Self.bufferGasEstimate(gasEstimate, curve: curve)
        let totalGas = bufferedGasEstimate.callGasLimit + bufferedGasEstimate.verificationGasLimit + bufferedGasEstimate.preVerificationGas
        let totalFeeWei = totalGas * resolvedGas.maxFeePerGas
        print("[AaSender] eth_estimateUserOperationGas → raw callGasLimit=\(gasEstimate.callGasLimit) verificationGasLimit=\(gasEstimate.verificationGasLimit) preVerificationGas=\(gasEstimate.preVerificationGas)")
        print("[AaSender] buffered → callGasLimit=\(bufferedGasEstimate.callGasLimit) verificationGasLimit=\(bufferedGasEstimate.verificationGasLimit) preVerificationGas=\(bufferedGasEstimate.preVerificationGas) total=\(totalGas)")
        print("[AaSender] estimated fee → \(totalGas) gas × \(Self.gwei(resolvedGas.maxFeePerGas)) gwei = \(totalFeeWei) wei (≈ \(Self.eth(totalFeeWei)))")

        // Replace stub paymasterAndData with the REAL signed paymasterAndData. Required before
        // userOpHash/sign/submit — bundler rejects the stub signature on submission (ERC-7677).
        let unsignedUserOpForPaymasterData = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: bufferedGasEstimate,
            gasPrices: resolvedGas,
            paymasterAndData: paymasterAndData
        )
        let userOpForPaymasterData = try withDummySignature(unsignedUserOpForPaymasterData, curve: curve, chain: chain)
        let realPaymasterAndData = try await pimlicoProvider.getPaymasterData(userOp: userOpForPaymasterData, mode: paymasterMode)
        print("[AaSender] pm_getPaymasterData → real paymasterAndData bytes=\(realPaymasterAndData.count)")
        guard let parsedPaymaster = Erc20PaymasterAndData.parse(realPaymasterAndData) else {
            print("[AaSender] paymasterAndData.parse → unsupported/invalid bytes=\(realPaymasterAndData.count)")
            throw SenderError.malformedPaymasterStub
        }
        logPaymasterAndData(parsedPaymaster, token: baseToken)

        // F4 invariant: Pimlico can theoretically rotate paymaster between stub and final
        // response. If we approved (or planned to approve) one paymaster but the final
        // UserOp references a different one, validation reverts on chain → retry blowup
        // → double-charge. Abort here instead of letting that pathology hit the user.
        guard parsedPaymaster.paymaster == stubPaymasterAddress else {
            throw SenderError.paymasterAddressChanged(stub: stubPaymasterAddress, final: parsedPaymaster.paymaster)
        }

        // EntryPoint.simulateHandleOp on the final-shape UserOp gives a realistic `paid`
        // (actualGasCost in wei) — the bundler's eth_estimateUserOperationGas only returns
        // gas LIMITS with safety margins (~2x overshoot). Used for the user-facing estimate.
        let unsignedSimulationUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: bufferedGasEstimate,
            gasPrices: resolvedGas,
            paymasterAndData: realPaymasterAndData
        )
        let simulationUserOp = try withDummySignature(unsignedSimulationUserOp, curve: curve, chain: chain)
        let simulation = try await simulateHandleOpProvider.simulate(userOp: simulationUserOp)
        let estimatedFeeWei = simulation.paid + parsedPaymaster.postOpGas * resolvedGas.maxFeePerGas
        print("[AaSender] simulateHandleOp → preOpGas=\(simulation.preOpGas) paid=\(simulation.paid) wei (≈ \(Self.eth(simulation.paid))); +postOpTail=\(parsedPaymaster.postOpGas)×maxFee → estimated=\(estimatedFeeWei) wei (≈ \(Self.eth(estimatedFeeWei)))")

        let feeBreakdown = AaFeeCalculator.breakdown(
            paidWei: simulation.paid,
            postOpGas: parsedPaymaster.postOpGas,
            bufferedGas: bufferedGasEstimate,
            gasPrices: resolvedGas,
            exchangeRate: parsedPaymaster.exchangeRate,
            scenario: feeScenario
        )

        let finalUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: bufferedGasEstimate,
            gasPrices: resolvedGas,
            paymasterAndData: realPaymasterAndData,
            signature: Data()
        )

        let userOpHash = PackedUserOperation.hash(userOp: finalUserOp, entryPoint: entryPoint, chainId: chainId)
        print("[AaSender] userOpHash=\(userOpHash.hs.hex)")

        let transactionDecoration = evmKit.decorate(transactionData: transactionData)
        let decoration = decorator.decorate(
            baseToken: baseToken,
            transactionData: transactionData,
            transactionDecoration: transactionDecoration
        )

        return PreparedUserOp(
            userOp: finalUserOp,
            userOpHash: userOpHash,
            isFreshDeployment: isFreshDeployment,
            gasEstimate: bufferedGasEstimate,
            gasPrices: resolvedGas,
            paymasterMode: paymasterMode,
            baseToken: baseToken,
            curve: curve,
            decoration: decoration,
            feeBreakdown: feeBreakdown
        )
    }

    /// Sign via passkey, submit via bundler, archive record. Returns userOpHash echoed by bundler.
    func submit(account: Account, prepared: PreparedUserOp) async throws -> Data {
        guard case let .passkeyOwned(credentialID) = account.type else {
            throw SenderError.notPasskeyAccount
        }

        guard let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: blockchainType) else {
            throw SenderError.unsupportedChain
        }

        print("[AaSender] submit → userOpHash=\(prepared.userOpHash.hs.hex) curve=\(prepared.curve.rawValue) prompting passkey…")

        let signatureBytes: Data
        switch prepared.curve {
        case .secp256k1:
            signatureBytes = try await EcdsaUserOpSigner.signViaPasskey(
                credentialID: credentialID,
                userOpHash: prepared.userOpHash,
                passkeyManager: passkeyManager,
                chain: chain
            )
        case .secp256r1:
            // Legacy P-256 path. Zero accounts in user DB after manual drain 2026-04-29
            // and CreateSmartAccountService now creates only .secp256k1, so this branch
            // is effectively dead. Throw rather than attempt a WebAuthn signature with
            // the wrong PasskeyManager type.
            throw SenderError.legacyCurveNotSupported
        }
        print("[AaSender] signature ready (bytes=\(signatureBytes.count))")

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
        print("[AaSender] eth_sendUserOperation → server userOpHash=\(serverUserOpHash.hs.hex) match=\(serverUserOpHash == prepared.userOpHash)")

        try archive(account: account, userOpHash: serverUserOpHash)
        print("[AaSender] archived PendingUserOperationRecord ✓")

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
        case paymasterAddressChanged(stub: EvmKit.Address, final: EvmKit.Address)
        case legacyCurveNotSupported
        case malformedAllowance
    }
}

// MARK: - Private helpers

private extension AaSender {
    static func gwei(_ wei: BigUInt) -> String {
        let whole = wei / BigUInt(1_000_000_000)
        let frac = wei % BigUInt(1_000_000_000)
        return "\(whole).\(String(format: "%03d", Int(frac / BigUInt(1_000_000))))"
    }

    static func eth(_ wei: BigUInt) -> String {
        let scale = BigUInt(10).power(18)
        let whole = wei / scale
        let frac = wei % scale
        // BigUInt.description always produces non-negative digits; Int conversion may truncate
        // for very large values, so format via string padding instead.
        let fracString = String(repeating: "0", count: 18 - String(frac).count) + String(frac)
        return "\(whole).\(fracString) ETH"
    }

    func smartAccountProfile(account: Account) throws -> SmartAccountProfile {
        guard case .passkeyOwned = account.type else {
            throw SenderError.notPasskeyAccount
        }
        guard let profile = try smartAccountManager.profile(accountId: account.id) else {
            throw SenderError.profileMissing
        }
        return profile
    }

    func fetchNonce(sender: EvmKit.Address) async throws -> BigUInt {
        let calldata = EntryPointV06.encodeGetNonce(sender: sender, key: 0)
        let result = try await evmKit.fetchCall(contractAddress: entryPoint, data: calldata, defaultBlockParameter: .latest)
        return try EntryPointV06.decodeGetNonce(result)
    }

    func fetchStandardGasPrice() async throws -> PimlicoProvider.GasPrices.Tier {
        try await pimlicoProvider.getUserOperationGasPrice().standard
    }

    func buildInitCode(publicKeyX: Data, publicKeyY: Data, curve: SignatureCurve) -> Data {
        guard let aa = ChainAddresses.aa(for: blockchainType) else {
            return Data()
        }

        let owner: Data
        let verificationFacet: EvmKit.Address
        switch curve {
        case .secp256r1:
            owner = (try? BarzFactory.encodeSecp256r1PublicKey(x: publicKeyX, y: publicKeyY)) ?? Data()
            verificationFacet = aa.secp256r1VerificationFacet
        case .secp256k1:
            owner = (try? BarzFactory.encodeSecp256k1Owner(x: publicKeyX, y: publicKeyY)) ?? Data()
            verificationFacet = aa.secp256k1VerificationFacet
        }

        return BarzFactory.buildInitCode(
            factory: ChainAddresses.barzFactory,
            verificationFacet: verificationFacet,
            owner: owner,
            salt: 0
        )
    }

    /// TODO: revisit approve amount strategy — currently infinity
    /// (memory: project_aa_paymaster_approval_todo).
    func buildApproveCall(token: EvmKit.Address, spender: EvmKit.Address) throws -> UserOperationCallData {
        let eip20Kit = try Eip20Kit.Kit.instance(evmKit: evmKit, contractAddress: token)
        let approveTxData = eip20Kit.approveTransactionData(
            spenderAddress: spender,
            amount: BigUInt(2).power(256) - 1
        )
        return UserOperationCallData(target: token, value: 0, data: approveTxData.input)
    }

    func buildUserCall(transactionData: TransactionData) -> UserOperationCallData {
        UserOperationCallData(target: transactionData.to, value: transactionData.value, data: transactionData.input)
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

    func withDummySignature(_ userOp: UserOperation, curve: SignatureCurve, chain: EvmKit.Chain) throws -> UserOperation {
        let signature: Data
        switch curve {
        case .secp256k1:
            let userOpHash = PackedUserOperation.hash(userOp: userOp, entryPoint: entryPoint, chainId: chainId)
            signature = try EcdsaUserOpSigner.dummySignature(userOpHash: userOpHash, chain: chain)
        case .secp256r1:
            signature = Secp256r1VerificationFacet.dummySignature()
        }

        return userOp.withSignature(signature)
    }

    /// Buffers verificationGasLimit. Pimlico estimator is accurate for callGas and
    /// preVerification but tight on verification. The buffer protects against:
    ///  - secp256r1: FCL_ELLIPTIC_ZZ Solidity P-256 verification on Mainnet costs
    ///    ~500-600k gas. Hard floor 700k + x4 multiplier observed empirically
    ///    (vGL=161k → OOG at SUB; vGL=322k → OOG at ADDMOD; vGL=700k succeeds).
    ///  - secp256k1: ecrecover precompile is ~3k gas, deterministic. Modest 1.3x
    ///    safety margin is enough.
    static func bufferGasEstimate(_ estimate: PimlicoProvider.GasEstimate, curve: SignatureCurve) -> PimlicoProvider.GasEstimate {
        let bufferedVerification: BigUInt
        switch curve {
        case .secp256r1:
            let scaled = estimate.verificationGasLimit * 4
            bufferedVerification = max(scaled, BigUInt(700_000))
        case .secp256k1:
            bufferedVerification = estimate.verificationGasLimit * 13 / 10
        }
        return PimlicoProvider.GasEstimate(
            callGasLimit: estimate.callGasLimit,
            verificationGasLimit: bufferedVerification,
            preVerificationGas: estimate.preVerificationGas
        )
    }

    func logPaymasterAndData(_ parsed: Erc20PaymasterAndData.Parsed, token: Token) {
        print("[AaSender] paymasterAndData.parse → paymaster=\(parsed.paymaster.eip55) combined=0x\(String(format: "%02x", parsed.combinedByte)) mode=\(parsed.modeName) allowAllBundlers=\(parsed.allowAllBundlers) erc20Flags=0x\(String(format: "%02x", parsed.erc20Flags)) constantFeePresent=\(parsed.constantFeePresent) recipientPresent=\(parsed.recipientPresent) preFundPresent=\(parsed.preFundPresent) signatureBytes=\(parsed.signatureBytes)")
        print("[AaSender] paymasterAndData.erc20 → token=\(parsed.token.eip55) treasury=\(parsed.treasury.eip55) validAfter=\(parsed.validAfter) validUntil=\(parsed.validUntil) postOpGas=\(parsed.postOpGas) exchangeRate=\(parsed.exchangeRate) (≈ \(Self.tokenAmount(parsed.exchangeRate, decimals: token.decimals)) \(token.coin.code)/ETH) paymasterValidationGasLimit=\(parsed.paymasterValidationGasLimit)")
        print("[AaSender] paymasterAndData.charge → preFundInToken=\(parsed.preFundInToken) raw (≈ \(Self.tokenAmount(parsed.preFundInToken, decimals: token.decimals)) \(token.coin.code)) constantFee=\(parsed.constantFee) raw (≈ \(Self.tokenAmount(parsed.constantFee, decimals: token.decimals)) \(token.coin.code)) recipient=\(parsed.recipient?.eip55 ?? "nil"); postOp transferFrom will charge actual cost")
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
            lastPolledAt: nil
        )
        try smartAccountManager.savePendingOperation(record: record)
    }
}

private extension AaSender {
    static func tokenAmount(_ rawAmount: BigUInt, decimals: Int) -> String {
        (Decimal(bigUInt: rawAmount, decimals: decimals) ?? 0).description
    }
}
