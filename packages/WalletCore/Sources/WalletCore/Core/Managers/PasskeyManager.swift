import AuthenticationServices
import Foundation
import HdWalletKit

public class PasskeyManager: NSObject {
    // PRF salt — the credential-bound input that derives the wallet seed. MUST be identical for the
    // registration-PRF and assertion-PRF paths, else the create-time seed wouldn't match the sign-time
    // seed and funds derived from it would be unrecoverable.
    private static let prfSalt = Data("wallet".utf8)

    // Relying-party domain (WebAuthn RP ID) the passkey is bound to. No default — every caller passes it
    // explicitly (from its app's AppConfig), so a forgotten domain is a compile error rather than a silent
    // wrong-domain credential that can't assert.
    private let domain: String

    public init(domain: String) {
        self.domain = domain
        super.init()
    }

    private var assertionContinuation: CheckedContinuation<PrfOutput, Error>?
    private var registrationContinuation: CheckedContinuation<Registration, Error>?
    private var isCrossDeviceAssertion: Bool = false

    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    // Convenience returning just the credentialID, so existing callers are unchanged.
    // Use `register` when the full registration result (incl. attestation) is needed.
    func create(name: String) async throws -> Data {
        try await register(name: name).credentialID
    }

    func register(name: String, requestPRF: Bool = false) async throws -> Registration {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: domain
        )

        let request = provider.createCredentialRegistrationRequest(
            challenge: generateChallenge(),
            name: name,
            userID: Data("\(name)::\(UUID().uuidString)".utf8)
        )

        // Request PRF evaluation during registration (iOS 18) with the SAME salt as assertion, so the
        // wallet seed can come from the single create ceremony (1 Face ID). The authenticator may still
        // return no PRF here — `registerWithPRF` then falls back to a PRF assertion on the same credential.
        if requestPRF, #available(iOS 18.0, *) {
            request.prf = .inputValues(.init(saltInput1: Self.prfSalt))
        }

        return try await withCheckedThrowingContinuation { (c: CheckedContinuation<Registration, Error>) in
            registrationContinuation = c
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // One-call create ceremony for a passkey-owned wallet: returns the attestation (it embeds the
    // credential public key for on-chain validators) AND the wallet mnemonic (from PRF), so the
    // orchestrator gets both from a single entry point.
    //
    // 1 Face ID: PRF is requested during the registration ceremony, so one prompt yields both the
    // attestation and the seed. If the authenticator declines to evaluate PRF at registration, it falls
    // back to a PRF assertion on the SAME credential (a second Face ID) — never a second registration,
    // so it can't strand a credential.
    func registerWithPRF(name: String) async throws -> RegistrationWithSeed {
        guard #available(iOS 18.0, *) else { throw PasskeyError.prfNotSupported }

        let registration = try await register(name: name, requestPRF: true)

        let mnemonic: [String]
        if let prf = registration.prfOutput, !prf.isEmpty {
            // 1 Face ID: the authenticator evaluated PRF during registration.
            mnemonic = Mnemonic.generate(entropy: prf)
        } else {
            // The authenticator deferred PRF to assertion → derive the seed via a PRF assertion on the
            // SAME credential (a second Face ID, but never a second registration → no stranded credential).
            mnemonic = try await loginWith(credentialID: registration.credentialID).mnemonic
        }

        return RegistrationWithSeed(
            credentialID: registration.credentialID,
            attestationObject: registration.attestationObject,
            mnemonic: mnemonic
        )
    }

    public func loginWith(credentialID: Data) async throws -> Passkey {
        try await assert(credentialID: credentialID)
    }

    func login() async throws -> Passkey {
        try await assert(credentialID: nil)
    }

    private func assert(credentialID: Data?) async throws -> Passkey {
        guard #available(iOS 18.0, *) else {
            throw PasskeyError.prfNotSupported
        }

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: domain
        )
        let request = provider.createCredentialAssertionRequest(
            challenge: generateChallenge()
        )

        request.prf = .inputValues(.init(saltInput1: Self.prfSalt))

        if let credentialID {
            request.allowedCredentials = [
                ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: credentialID),
            ]
        }

        isCrossDeviceAssertion = credentialID == nil

        let prfOutput = try await withCheckedThrowingContinuation { continuation in
            assertionContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        let name = prfOutput.userId.components(separatedBy: "::").first ?? ""
        let mnemonic = Mnemonic.generate(entropy: prfOutput.data)
        return .init(credentialID: prfOutput.credentialID, name: name, mnemonic: mnemonic)
    }
}

extension PasskeyManager: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let reg = authorization.credential
            as? ASAuthorizationPlatformPublicKeyCredentialRegistration
        {
            // Keep the raw attestation (it carries the credential's public key) alongside credentialID.
            // On iOS 18, also read the PRF output if it was evaluated at registration (enables 1-Face-ID
            // create); nil otherwise and the caller falls back to a PRF assertion.
            var prfOutput: Data?
            if #available(iOS 18.0, *), let prf = reg.prf, let first = prf.first {
                prfOutput = first.withUnsafeBytes { Data($0) }
            }
            registrationContinuation?.resume(returning: Registration(credentialID: reg.credentialID, attestationObject: reg.rawAttestationObject, prfOutput: prfOutput))
            registrationContinuation = nil
            return
        }

        guard let credential = authorization.credential
            as? ASAuthorizationPlatformPublicKeyCredentialAssertion
        else {
            assertionContinuation?.resume(throwing: PasskeyError.authenticationFailed)
            assertionContinuation = nil
            return
        }

        guard #available(iOS 18.0, *) else {
            assertionContinuation?.resume(throwing: PasskeyError.prfNotSupported)
            assertionContinuation = nil
            return
        }

        guard let prfAssertionOutput = credential.prf else {
            let error: PasskeyError = isCrossDeviceAssertion ? .prfNotSupportedRemote : .prfNotSupported
            assertionContinuation?.resume(throwing: error)
            assertionContinuation = nil
            return
        }

        let userId = String(data: credential.userID, encoding: .utf8)
        let prfOutput = prfAssertionOutput.first.withUnsafeBytes { Data($0) }

        assertionContinuation?.resume(returning: PrfOutput(credentialID: credential.credentialID, userId: userId ?? "", data: prfOutput))
        assertionContinuation = nil
    }

    public func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let walletError = Self.map(error: error)

        registrationContinuation?.resume(throwing: walletError)
        registrationContinuation = nil
        assertionContinuation?.resume(throwing: walletError)
        assertionContinuation = nil
    }

    private static func map(error: Error) -> PasskeyError {
        guard let authError = error as? ASAuthorizationError else {
            return .authenticationFailed
        }

        switch authError.code {
        case .canceled:
            return .userCanceled
        case .notInteractive:
            return .noCredentials
        case .failed:
            let nsError = error as NSError
            let reason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? "nil"
            print("PasskeyManager failed (1004): \(nsError.localizedDescription) | reason=\(reason)")
            return .authenticationFailed
        default:
            return .authenticationFailed
        }
    }
}

extension PasskeyManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

extension PasskeyManager {
    // Result of a passkey registration: the credentialID plus the raw WebAuthn attestation (it embeds
    // the credential's public key). `attestationObject` is nil if the authenticator returned none.
    struct Registration {
        let credentialID: Data
        let attestationObject: Data?
        // PRF output evaluated AT registration (iOS 18), when requested and returned by the authenticator;
        // nil if PRF wasn't requested or the authenticator deferred it to an assertion.
        let prfOutput: Data?
    }

    // Result of the combined create ceremony (`registerWithPRF`): the attestation (public key) plus the
    // wallet mnemonic derived from the credential's PRF output.
    struct RegistrationWithSeed {
        let credentialID: Data
        let attestationObject: Data?
        let mnemonic: [String]
    }

    private struct PrfOutput {
        let credentialID: Data
        let userId: String
        let data: Data
    }

    public enum PasskeyError: Error, LocalizedError {
        case prfNotSupported
        case prfNotSupportedRemote
        case authenticationFailed
        case userCanceled
        case noCredentials
        case noWalletsFound
        case passkeyLost

        public var errorDescription: String? {
            switch self {
            case .prfNotSupported: return "This device requires iOS 18 or later for passkey wallet login."
            case .prfNotSupportedRemote: return "The device you scanned from doesn't support PRF."
            case .authenticationFailed: return "Authentication failed. Please try again."
            case .userCanceled: return "Authentication was canceled."
            case .noCredentials: return "No credentials found."
            case .noWalletsFound: return "No wallets found. Please create a new wallet."
            case .passkeyLost: return "Passkey not found. Please restore from backup."
            }
        }
    }
}
