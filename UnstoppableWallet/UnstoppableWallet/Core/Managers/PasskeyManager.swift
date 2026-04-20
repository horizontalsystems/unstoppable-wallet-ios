import AuthenticationServices
import Foundation
import HdWalletKit

class PasskeyManager: NSObject {
    private let relyingParty = "unstoppable.money"

    private var assertionContinuation: CheckedContinuation<PrfOutput, Error>?
    private var registrationContinuation: CheckedContinuation<Data, Error>?
    private var isCrossDeviceAssertion: Bool = false

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
            let error: PasskeyError = isCrossDeviceAssertion ? .prfNotSupportedRemote : .prfNotSupported
            assertionContinuation?.resume(throwing: error)
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
        case prfNotSupportedRemote
        case authenticationFailed
        case userCanceled
        case noCredentials
        case noWalletsFound
        case passkeyLost

        var errorDescription: String? {
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
