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
