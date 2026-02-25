import AuthenticationServices
import Foundation
import UIKit

class BackupSharedWebCredentialsService: NSObject, IBackupPasswordStorage {
    private static let server = "unstoppable.money"

    private var loadContinuation: CheckedContinuation<String?, Never>?

    var requiresUnlock: Bool { false }

    func save(password: String, account: String) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            SecAddSharedWebCredential(
                Self.server as CFString,
                account as CFString,
                password as CFString
            ) { error in
                if let error {
                    print("SecAddSharedWebCredential error: \(error)")

                    continuation.resume(throwing: error)
                } else {
                    print("SecAddSharedWebCredential success")
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func load(account _: String) async -> String? {
        await withCheckedContinuation { continuation in
            loadContinuation = continuation

            let provider = ASAuthorizationPasswordProvider()
            let request = provider.createRequest()

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self

            objc_setAssociatedObject(controller, "delegate", self, .OBJC_ASSOCIATION_RETAIN)

            controller.performRequests(options: .preferImmediatelyAvailableCredentials)
        }
    }

    @discardableResult
    func delete(account: String) async -> Bool {
        await withCheckedContinuation { continuation in
            SecAddSharedWebCredential(
                Self.server as CFString,
                account as CFString,
                nil
            ) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }
}

extension BackupSharedWebCredentialsService: ASAuthorizationControllerDelegate {
    func authorizationController(controller _: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASPasswordCredential else {
            loadContinuation?.resume(returning: nil)
            loadContinuation = nil
            return
        }

        loadContinuation?.resume(returning: credential.password)
        loadContinuation = nil
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError _: Error) {
        loadContinuation?.resume(returning: nil)
        loadContinuation = nil
    }
}

extension BackupSharedWebCredentialsService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
