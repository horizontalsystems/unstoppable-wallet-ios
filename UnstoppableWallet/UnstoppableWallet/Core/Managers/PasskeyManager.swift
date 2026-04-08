import AuthenticationServices
import Foundation
import HdWalletKit

class PasskeyManager: NSObject {
    private let relyingParty = "unstoppable.money"

    private var assertionContinuation: CheckedContinuation<PrfOutput, Error>?
    private var registrationContinuation: CheckedContinuation<Void, Error>?

    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    func create(name: String) async throws {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingParty
        )

        let userId = "\(name)::\(UUID().uuidString)"

        let request = provider.createCredentialRegistrationRequest(
            challenge: generateChallenge(),
            name: name,
            userID: Data(userId.utf8)
        )

        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            registrationContinuation = c
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func login() async throws -> Passkey {
        guard #available(iOS 18.0, *) else {
            throw PasskeyError.prfNotSupported
        }

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingParty
        )
        let request = provider.createCredentialAssertionRequest(
            challenge: generateChallenge()
        )

        request.prf = .inputValues(.init(saltInput1: Data("wallet".utf8)))

        let prfOutput = try await withCheckedThrowingContinuation { continuation in
            assertionContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self

            // preferImmediatelyAvailableCredentials — only succeeds if a passkey
            // already exists for this rpID. Fails silently (no UI) if none found.
            // This avoids showing the "Create passkey?" sheet when we expect assertion.
            controller.performRequests(options: .preferImmediatelyAvailableCredentials)
        }

        let name = prfOutput.userId.components(separatedBy: "::").first ?? ""
        let mnemonic = Mnemonic.generate(entropy: prfOutput.data)

        return .init(name: name, mnemonic: mnemonic)
    }
}

extension PasskeyManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        // Registration success — no PRF output at this stage
        if authorization.credential is ASAuthorizationPlatformPublicKeyCredentialRegistration {
            registrationContinuation?.resume(returning: ())
            registrationContinuation = nil
            return
        }

        // Assertion success — extract PRF output
        guard let credential = authorization.credential
            as? ASAuthorizationPlatformPublicKeyCredentialAssertion
        else {
            assertionContinuation?.resume(throwing: PasskeyError.authenticationFailed)
            assertionContinuation = nil
            return
        }

        // credential.prf is iOS 18+ only
        guard #available(iOS 18.0, *) else {
            assertionContinuation?.resume(throwing: PasskeyError.prfNotSupported)
            assertionContinuation = nil
            return
        }

        // credential.prf returns ASAuthorizationPublicKeyCredentialPRFAssertionOutput?
        // .first is a SymmetricKey — extract raw bytes via withUnsafeBytes
        guard let prfAssertionOutput = credential.prf else {
            // PRF not evaluated — device doesn't support it (pre-iOS 18 iCloud Keychain)
            assertionContinuation?.resume(throwing: PasskeyError.prfNotSupported)
            assertionContinuation = nil
            return
        }

        let userId = String(data: credential.userID, encoding: .utf8)
        let prfOutput = prfAssertionOutput.first.withUnsafeBytes { Data($0) }

        assertionContinuation?.resume(returning: PrfOutput(userId: userId ?? "", data: prfOutput))
        assertionContinuation = nil
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let walletError: PasskeyError

        if let authError = error as? ASAuthorizationError {
            switch authError.code.rawValue {
            case 1001:
                walletError = .noCredentials
            default:
                walletError = .authenticationFailed
            }
        } else {
            walletError = .authenticationFailed
        }

        registrationContinuation?.resume(throwing: walletError)
        registrationContinuation = nil
        assertionContinuation?.resume(throwing: walletError)
        assertionContinuation = nil
    }
}

extension PasskeyManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

extension PasskeyManager {
    private struct PrfOutput {
        let userId: String
        let data: Data
    }

    private enum PasskeyError: Error, LocalizedError {
        case prfNotSupported // device/OS doesn't support PRF (pre-iOS 18)
        case authenticationFailed // unexpected credential type returned
        case userCanceled // user dismissed the Face ID sheet
        case noCredentials // iCloud has no wallet IDs — new user
        case noWalletsFound // iCloud has no wallet IDs — new user
        case passkeyLost // iCloud has wallet IDs but passkey assertion failed

        var errorDescription: String? {
            switch self {
            case .prfNotSupported: return "This device requires iOS 18 or later for passkey wallet login."
            case .authenticationFailed: return "Authentication failed. Please try again."
            case .userCanceled: return "Authentication was canceled."
            case .noCredentials: return "No Credentials"
            case .noWalletsFound: return "No wallets found. Please create a new wallet."
            case .passkeyLost: return "Passkey not found. Please restore from backup."
            }
        }
    }
}
