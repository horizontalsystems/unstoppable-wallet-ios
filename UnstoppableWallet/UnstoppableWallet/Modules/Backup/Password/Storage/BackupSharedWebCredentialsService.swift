import Foundation
import AuthenticationServices
import UIKit

class BackupSharedWebCredentialsService: NSObject, IBackupPasswordStorage {
    private static let server = "unstoppable.money"

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

    func load(account: String) async -> String? {
        await withCheckedContinuation { continuation in
            let provider = ASAuthorizationPasswordProvider()
            let request = provider.createRequest()

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self

            // Store continuation to use in delegate
            self.loadContinuation = continuation
            controller.performRequests()
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

    private var loadContinuation: CheckedContinuation<String?, Never>?
}

extension BackupSharedWebCredentialsService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASPasswordCredential else {
            loadContinuation?.resume(returning: nil)
            loadContinuation = nil
            return
        }

        loadContinuation?.resume(returning: credential.password)
        loadContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        loadContinuation?.resume(returning: nil)
        loadContinuation = nil
    }
}

extension BackupSharedWebCredentialsService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
