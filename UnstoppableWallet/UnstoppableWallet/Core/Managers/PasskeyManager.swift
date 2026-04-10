import AuthenticationServices
import Foundation
import HdWalletKit

class PasskeyManager: NSObject {
    private let relyingParty = "unstoppable.money"

    private var assertionContinuation: CheckedContinuation<PrfOutput, Error>?
    private var registrationContinuation: CheckedContinuation<Data, Error>?

    private func generateChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    func create(name: String) async throws -> Data {
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: relyingParty
        )

        let request = provider.createCredentialRegistrationRequest(
            challenge: generateChallenge(),
            name: name,
            userID: Data("\(name)::\(UUID().uuidString)".utf8)
        )

        return try await withCheckedThrowingContinuation { (c: CheckedContinuation<Data, Error>) in
            registrationContinuation = c
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func loginWith(credentialID: Data) async throws -> Passkey {
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
            relyingPartyIdentifier: relyingParty
        )
        let request = provider.createCredentialAssertionRequest(
            challenge: generateChallenge()
        )

        request.prf = .inputValues(.init(saltInput1: Data("wallet".utf8)))

        if let credentialID {
            request.allowedCredentials = [
                ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: credentialID),
            ]
        }

        let prfOutput = try await withCheckedThrowingContinuation { continuation in
            assertionContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            if credentialID != nil {
                controller.performRequests()
            } else {
                controller.performRequests(options: .preferImmediatelyAvailableCredentials)
            }
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
        if let reg = authorization.credential
            as? ASAuthorizationPlatformPublicKeyCredentialRegistration
        {
            registrationContinuation?.resume(returning: reg.credentialID)
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
            case 1001: walletError = .noCredentials
            default: walletError = .authenticationFailed
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

    enum PasskeyError: Error, LocalizedError {
        case prfNotSupported
        case authenticationFailed
        case userCanceled
        case noCredentials
        case noWalletsFound
        case passkeyLost

        var errorDescription: String? {
            switch self {
            case .prfNotSupported: return "This device requires iOS 18 or later for passkey wallet login."
            case .authenticationFailed: return "Authentication failed. Please try again."
            case .userCanceled: return "Authentication was canceled."
            case .noCredentials: return "No credentials found."
            case .noWalletsFound: return "No wallets found. Please create a new wallet."
            case .passkeyLost: return "Passkey not found. Please restore from backup."
            }
        }
    }
}
