import AuthenticationServices
import Foundation
import UIKit

// WebAuthn/passkey manager for ERC-4337 smart-account flow. Separate from the legacy PasskeyManager
// (which is PRF→mnemonic). This one returns raw WebAuthn material for downstream signing.
//
// Threading contract: all public API must be called from the main thread (matches existing
// PasskeyManager; ASAuthorizationController requires main-thread presentation). Reentry while a
// flow is in-flight throws AAError.busy.
class SmartAccountPasskeyManager: NSObject {
    private let relyingPartyIdentifier = "unstoppable.money"
    private let requester: PasskeyAuthorizationRequesting

    private var registrationContinuation: CheckedContinuation<Registration, Error>?
    private var assertionContinuation: CheckedContinuation<WebAuthnSignature, Error>?

    private var isBusy: Bool {
        registrationContinuation != nil || assertionContinuation != nil
    }

    init(requester: PasskeyAuthorizationRequesting = SystemPasskeyAuthorizationRequester()) {
        self.requester = requester
        super.init()
    }

    func register(name: String) async throws -> Registration {
        if isBusy { throw AAError.busy }

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingPartyIdentifier
        )
        let request = provider.createCredentialRegistrationRequest(
            challenge: randomChallenge(32),
            name: name,
            userID: Data("\(name)::\(UUID().uuidString)".utf8) // new UUID per call — intentional (no overwrite semantics).
        )
        // .direct strongly requests authData-bearing attestation object. Apple platform authenticator
        // typically complies, but nil is still handled as AAError.missingAttestation at runtime.
        request.attestationPreference = .direct

        return try await withCheckedThrowingContinuation { continuation in
            registrationContinuation = continuation
            presentController(requests: [request])
        }
    }

    func assertForSigning(credentialID: Data, challenge: Data) async throws -> WebAuthnSignature {
        if isBusy { throw AAError.busy }

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingPartyIdentifier
        )
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        request.allowedCredentials = [
            ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: credentialID),
        ]

        return try await withCheckedThrowingContinuation { continuation in
            assertionContinuation = continuation
            presentController(requests: [request])
        }
    }

    private func randomChallenge(_ count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    private func presentController(requests: [ASAuthorizationRequest]) {
        requester.perform(requests: requests, delegate: self, contextProvider: self)
    }

    // Finish helpers: nil the continuation slot BEFORE resume to keep the manager reusable if the
    // caller immediately starts a new flow inside the resume-handler.
    private func finishRegistration(_ result: Result<Registration, Error>) {
        let continuation = registrationContinuation
        registrationContinuation = nil
        continuation?.resume(with: result)
    }

    private func finishAssertion(_ result: Result<WebAuthnSignature, Error>) {
        let continuation = assertionContinuation
        assertionContinuation = nil
        continuation?.resume(with: result)
    }

    private func finishAny(with error: Error) {
        if registrationContinuation != nil {
            finishRegistration(.failure(error))
        } else if assertionContinuation != nil {
            finishAssertion(.failure(error))
        }
    }
}

extension SmartAccountPasskeyManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let reg = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            guard let rawAttestation = reg.rawAttestationObject else {
                finishRegistration(.failure(AAError.missingAttestation))
                return
            }
            do {
                let parsed = try PasskeyAttestationDecoder.decode(rawAttestationObject: rawAttestation)
                guard parsed.credentialID == reg.credentialID else {
                    finishRegistration(.failure(AAError.credentialIdMismatch))
                    return
                }
                finishRegistration(.success(parsed))
            } catch {
                finishRegistration(.failure(error))
            }
            return
        }

        if let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            let signature = WebAuthnSignature(
                authenticatorData: assertion.rawAuthenticatorData,
                clientDataJSON: assertion.rawClientDataJSON,
                signature: assertion.signature
            )
            finishAssertion(.success(signature))
            return
        }

        finishAny(with: AAError.unexpectedCredentialType)
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        finishAny(with: Self.map(error: error))
    }

    private static func map(error: Error) -> AAError {
        guard let authError = error as? ASAuthorizationError else {
            return .authenticationFailed
        }
        switch authError.code {
        case .canceled: return .userCanceled
        case .notInteractive: return .noCredentials
        default: return .authenticationFailed
        }
    }
}

extension SmartAccountPasskeyManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

extension SmartAccountPasskeyManager {
    // P-256 coordinates per COSE RFC 8152 §13.1.1: 32-byte big-endian unsigned integers.
    struct Registration: Equatable, Hashable {
        let credentialID: Data
        let publicKeyX: Data
        let publicKeyY: Data
    }

    enum AAError: Error, LocalizedError {
        case busy
        case missingAttestation
        case credentialIdMismatch
        case unexpectedCredentialType
        case userCanceled
        case authenticationFailed
        case noCredentials

        var errorDescription: String? {
            switch self {
            case .busy: return "Another passkey operation is already in progress."
            case .missingAttestation: return "Passkey registration did not return an attestation object."
            case .credentialIdMismatch: return "Decoded credential ID does not match the authenticator."
            case .unexpectedCredentialType: return "Unexpected credential type received from the authenticator."
            case .userCanceled: return "Authentication was canceled."
            case .authenticationFailed: return "Authentication failed. Please try again."
            case .noCredentials: return "No passkey credentials available."
            }
        }
    }
}
