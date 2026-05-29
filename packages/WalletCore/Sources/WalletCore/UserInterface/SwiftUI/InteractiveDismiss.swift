import SwiftUI

class ModalHostingController<Content: View>: UIHostingController<Content>, UIAdaptivePresentationControllerDelegate {
    var canDismissSheet = true
    var onDismissalAttempt: (() -> Void)?

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        parent?.presentationController?.delegate = self
    }

    func presentationControllerShouldDismiss(_: UIPresentationController) -> Bool {
        canDismissSheet
    }

    func presentationControllerDidAttemptToDismiss(_: UIPresentationController) {
        onDismissalAttempt?()
    }
}

struct ModalView<T: View>: UIViewControllerRepresentable {
    let view: T
    let canDismissSheet: Bool
    let onDismissalAttempt: (() -> Void)?

    func makeUIViewController(context _: Context) -> ModalHostingController<T> {
        let controller = ModalHostingController(rootView: view)

        controller.canDismissSheet = canDismissSheet
        controller.onDismissalAttempt = onDismissalAttempt

        return controller
    }

    func updateUIViewController(_ uiViewController: ModalHostingController<T>, context _: Context) {
        uiViewController.rootView = view

        uiViewController.canDismissSheet = canDismissSheet
        uiViewController.onDismissalAttempt = onDismissalAttempt
    }
}

extension View {
    func interactiveDismiss(canDismissSheet: Bool, onDismissalAttempt: (() -> Void)? = nil) -> some View {
        ModalView(
            view: self,
            canDismissSheet: canDismissSheet,
            onDismissalAttempt: onDismissalAttempt
        ).edgesIgnoringSafeArea(.all)
    }
}
