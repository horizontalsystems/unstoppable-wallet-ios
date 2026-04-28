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
    private let decorator = EvmDecorator()

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

        let isFreshDeployment = !isDeployed
        let initCode = isFreshDeployment ? buildInitCode(publicKeyX: publicKeyX, publicKeyY: publicKeyY) : Data()
        print("[AaSender] initCode bytes=\(initCode.count) (fresh=\(isFreshDeployment))")

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
            print("[AaSender] paymaster lookup (erc20 stub) → paymaster=\(paymasterAddress!.eip55) (paymasterAndData bytes=\(erc20Stub.count))")

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

        let paymasterMode: PimlicoProvider.PaymasterMode = .erc20(token: tokenAddress)
        print("[AaSender] paymasterMode=erc20 (user-paid, Pimlico-balance fallback on postOp revert) fresh=\(isFreshDeployment) callData bytes=\(callData.count)")
        let paymasterAndData = try await pimlicoProvider.getPaymasterStubData(userOp: stubUserOp, mode: paymasterMode)
        print("[AaSender] pm_getPaymasterStubData → paymasterAndData bytes=\(paymasterAndData.count)")

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
        let totalGas = gasEstimate.callGasLimit + gasEstimate.verificationGasLimit + gasEstimate.preVerificationGas
        let totalFeeWei = totalGas * resolvedGas.maxFeePerGas
        print("[AaSender] eth_estimateUserOperationGas → callGasLimit=\(gasEstimate.callGasLimit) verificationGasLimit=\(gasEstimate.verificationGasLimit) preVerificationGas=\(gasEstimate.preVerificationGas) total=\(totalGas)")
        print("[AaSender] estimated fee → \(totalGas) gas × \(Self.gwei(resolvedGas.maxFeePerGas)) gwei = \(totalFeeWei) wei (≈ \(Self.eth(totalFeeWei)))")
        await logPimlicoTokenQuote(tokenAddress: tokenAddress, token: baseToken, gasEstimate: gasEstimate, gasPrices: resolvedGas)

        let userOpForPaymasterData = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: gasEstimate,
            gasPrices: resolvedGas,
            paymasterAndData: paymasterAndData,
            signature: Secp256r1VerificationFacet.dummySignature()
        )
        let realPaymasterAndData = try await pimlicoProvider.getPaymasterData(userOp: userOpForPaymasterData, mode: paymasterMode)
        print("[AaSender] pm_getPaymasterData → real paymasterAndData bytes=\(realPaymasterAndData.count)")
        logPaymasterAndData(realPaymasterAndData, token: baseToken)

        let finalUserOp = makeUserOp(
            sender: sender,
            nonce: resolvedNonce,
            initCode: initCode,
            callData: callData,
            gas: gasEstimate,
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
            gasEstimate: gasEstimate,
            gasPrices: resolvedGas,
            paymasterMode: paymasterMode,
            baseToken: baseToken,
            decoration: decoration
        )
    }

    /// Sign via passkey, submit via bundler, archive record. Returns userOpHash echoed by bundler.
    func submit(account: Account, prepared: PreparedUserOp) async throws -> Data {
        guard case let .passkeyOwned(credentialID, _, _) = account.type else {
            throw SenderError.notPasskeyAccount
        }

        print("[AaSender] submit → userOpHash=\(prepared.userOpHash.hs.hex) prompting passkey…")

        let signatureBytes = try await PasskeyUserOpSigner.sign(
            userOpHash: prepared.userOpHash,
            credentialID: credentialID,
            passkeyManager: passkeyManager
        )
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
    let decoration: EvmDecoration
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
        let fracString = String(repeating: "0", count: 18 - String(frac).count) + String(frac)
        return "\(whole).\(fracString) ETH"
    }

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

    func logPimlicoTokenQuote(
        tokenAddress: EvmKit.Address,
        token: Token,
        gasEstimate: PimlicoProvider.GasEstimate,
        gasPrices: PimlicoProvider.GasPrices.Tier
    ) async {
        do {
            let quotes = try await pimlicoProvider.getTokenQuotes(tokens: [tokenAddress])
            guard let quote = quotes.first(where: { $0.token.eip55.lowercased() == tokenAddress.eip55.lowercased() }) ?? quotes.first else {
                print("[AaSender] pimlico_getTokenQuotes → no quote for token=\(tokenAddress.eip55)")
                return
            }

            let requiredGas = gasEstimate.callGasLimit + gasEstimate.verificationGasLimit * 3 + gasEstimate.preVerificationGas
            let requiredPrefundWei = requiredGas * gasPrices.maxFeePerGas
            let maxCostInToken = Self.costInToken(
                gasCostWei: requiredPrefundWei,
                postOpGas: 0,
                actualUserOpFeePerGas: 0,
                exchangeRate: quote.exchangeRate
            )
            let uiGas = gasEstimate.callGasLimit + gasEstimate.verificationGasLimit + gasEstimate.preVerificationGas
            let uiFeeWei = uiGas * gasPrices.maxFeePerGas

            print("[AaSender] pimlico_getTokenQuotes → paymaster=\(quote.paymaster.eip55) token=\(quote.token.eip55) postOpGas=\(quote.postOpGas) exchangeRate=\(quote.exchangeRate) (\(Self.tokenAmount(quote.exchangeRate, decimals: token.decimals)) \(token.coin.code)/ETH) nativeUsd=\(quote.exchangeRateNativeToUsd) (\(Self.tokenAmount(quote.exchangeRateNativeToUsd, decimals: 6)) USD/ETH) balanceSlot=\(quote.balanceSlot) allowanceSlot=\(quote.allowanceSlot)")
            print("[AaSender] pimlico token cap → requiredGas=call+\(3)×verification+pre=\(requiredGas) prefundWei=\(requiredPrefundWei) (≈ \(Self.eth(requiredPrefundWei))) maxCostInToken=\(maxCostInToken) raw (≈ \(Self.tokenAmount(maxCostInToken, decimals: token.decimals)) \(token.coin.code)); cap/allowance only, not charged upfront when preFundInToken=0")
            print("[AaSender] fee display upper-bound → uiGas=call+verification+pre=\(uiGas) × maxFee=\(Self.gwei(gasPrices.maxFeePerGas)) gwei = \(uiFeeWei) wei (≈ \(Self.eth(uiFeeWei)))")
            print("[AaSender] postOp formula → tokenCharge = (EntryPoint.actualGasCost + postOpGas×actualUserOpFeePerGas) × exchangeRate / 1e18")
        } catch {
            print("[AaSender] pimlico_getTokenQuotes → failed: \(error)")
        }
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

    func logPaymasterAndData(_ paymasterAndData: Data, token: Token) {
        guard let parsed = Self.parseErc20PaymasterAndData(paymasterAndData) else {
            print("[AaSender] paymasterAndData.parse → unsupported/invalid bytes=\(paymasterAndData.count)")
            return
        }

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
            lastPolledAt: nil,
            bundlerUrl: pimlicoProvider.bundlerUrl
        )
        try smartAccountManager.savePendingOperation(record: record)
    }
}

private extension AaSender {
    struct ParsedErc20PaymasterAndData {
        let paymaster: EvmKit.Address
        let combinedByte: UInt8
        let mode: UInt8
        let allowAllBundlers: Bool
        let erc20Flags: UInt8
        let constantFeePresent: Bool
        let recipientPresent: Bool
        let preFundPresent: Bool
        let validUntil: BigUInt
        let validAfter: BigUInt
        let token: EvmKit.Address
        let postOpGas: BigUInt
        let exchangeRate: BigUInt
        let paymasterValidationGasLimit: BigUInt
        let treasury: EvmKit.Address
        let preFundInToken: BigUInt
        let constantFee: BigUInt
        let recipient: EvmKit.Address?
        let signatureBytes: Int

        var modeName: String {
            switch mode {
            case 0: return "verifying"
            case 1: return "erc20"
            default: return "unknown(\(mode))"
            }
        }
    }

    static func parseErc20PaymasterAndData(_ data: Data) -> ParsedErc20PaymasterAndData? {
        guard data.count >= 20 + 1 + 117 else {
            return nil
        }

        let paymaster = EvmKit.Address(raw: data.subdata(in: 0 ..< 20))
        let combinedByte = data[20]
        let mode = combinedByte >> 1
        let allowAllBundlers = (combinedByte & 0x01) != 0
        guard mode == 1 else {
            return nil
        }

        var offset = 21
        let erc20Flags = data[offset]
        let constantFeePresent = (erc20Flags & 0x01) != 0
        let recipientPresent = (erc20Flags & 0x02) != 0
        let preFundPresent = (erc20Flags & 0x04) != 0
        offset += 1

        guard data.count >= offset + 6 + 6 + 20 + 16 + 32 + 16 + 20 else {
            return nil
        }

        let validUntil = uint(data: data.subdata(in: offset ..< offset + 6))
        offset += 6
        let validAfter = uint(data: data.subdata(in: offset ..< offset + 6))
        offset += 6
        let token = EvmKit.Address(raw: data.subdata(in: offset ..< offset + 20))
        offset += 20
        let postOpGas = uint(data: data.subdata(in: offset ..< offset + 16))
        offset += 16
        let exchangeRate = uint(data: data.subdata(in: offset ..< offset + 32))
        offset += 32
        let paymasterValidationGasLimit = uint(data: data.subdata(in: offset ..< offset + 16))
        offset += 16
        let treasury = EvmKit.Address(raw: data.subdata(in: offset ..< offset + 20))
        offset += 20

        var preFundInToken = BigUInt(0)
        if preFundPresent {
            guard data.count >= offset + 16 else { return nil }
            preFundInToken = uint(data: data.subdata(in: offset ..< offset + 16))
            offset += 16
        }

        var constantFee = BigUInt(0)
        if constantFeePresent {
            guard data.count >= offset + 16 else { return nil }
            constantFee = uint(data: data.subdata(in: offset ..< offset + 16))
            offset += 16
        }

        var recipient: EvmKit.Address?
        if recipientPresent {
            guard data.count >= offset + 20 else { return nil }
            recipient = EvmKit.Address(raw: data.subdata(in: offset ..< offset + 20))
            offset += 20
        }

        let signatureBytes = data.count - offset
        guard signatureBytes == 64 || signatureBytes == 65 else {
            return nil
        }

        return ParsedErc20PaymasterAndData(
            paymaster: paymaster,
            combinedByte: combinedByte,
            mode: mode,
            allowAllBundlers: allowAllBundlers,
            erc20Flags: erc20Flags,
            constantFeePresent: constantFeePresent,
            recipientPresent: recipientPresent,
            preFundPresent: preFundPresent,
            validUntil: validUntil,
            validAfter: validAfter,
            token: token,
            postOpGas: postOpGas,
            exchangeRate: exchangeRate,
            paymasterValidationGasLimit: paymasterValidationGasLimit,
            treasury: treasury,
            preFundInToken: preFundInToken,
            constantFee: constantFee,
            recipient: recipient,
            signatureBytes: signatureBytes
        )
    }

    static func uint(data: Data) -> BigUInt {
        BigUInt(data.hs.hex, radix: 16) ?? 0
    }

    static func costInToken(
        gasCostWei: BigUInt,
        postOpGas: BigUInt,
        actualUserOpFeePerGas: BigUInt,
        exchangeRate: BigUInt
    ) -> BigUInt {
        ((gasCostWei + postOpGas * actualUserOpFeePerGas) * exchangeRate) / BigUInt(10).power(18)
    }

    static func tokenAmount(_ rawAmount: BigUInt, decimals: Int) -> String {
        (Decimal(bigUInt: rawAmount, decimals: decimals) ?? 0).description
    }
}
