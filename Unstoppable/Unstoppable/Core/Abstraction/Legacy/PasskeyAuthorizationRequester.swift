// Legacy — passkey-native AA (P-256 / FCL_ELLIPTIC_ZZ).
// Frozen 2026-04-30: no new accounts of this type are created.
// TODO-A: delete this Legacy/ folder when strategic decision to drop
// passkey-AA support permanently is made.

import AuthenticationServices
import Foundation

// Seam over ASAuthorizationController.performRequests so SmartAccountPasskeyManager can be
// unit-tested for reentry / busy behavior without going through the real iOS API.
protocol PasskeyAuthorizationRequesting {
    func perform(
        requests: [ASAuthorizationRequest],
        delegate: ASAuthorizationControllerDelegate,
        contextProvider: ASAuthorizationControllerPresentationContextProviding
    )
}

struct SystemPasskeyAuthorizationRequester: PasskeyAuthorizationRequesting {
    func perform(
        requests: [ASAuthorizationRequest],
        delegate: ASAuthorizationControllerDelegate,
        contextProvider: ASAuthorizationControllerPresentationContextProviding
    ) {
        let controller = ASAuthorizationController(authorizationRequests: requests)
        controller.delegate = delegate
        controller.presentationContextProvider = contextProvider
        controller.performRequests()
    }
}
