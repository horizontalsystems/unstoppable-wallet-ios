import Combine
import SwiftUI
import UIKit

class TextFieldAlertViewController: UIViewController {
    private let alertTitle: String
    private let message: String?
    @Published private var text: String = ""
    private var isPresented: Binding<Bool>?
    private var amountChanged: ((String) -> Void)?

    private var subscription: AnyCancellable?

    init(title: String, message: String?, initial: String, isPresented: Binding<Bool>?, amountChanged: ((String) -> Void)?) {
        alertTitle = title
        self.message = message
        self.text = initial
        self.isPresented = isPresented
        self.amountChanged = amountChanged

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentAlertController()
    }

    private func presentAlertController() {
        guard subscription == nil else { return } // present only once

        let vc = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)

        // add a textField and create a subscription to update the `text` binding
        vc.addTextField { [weak self] textField in
            guard let self else { return }
            textField.keyboardType = .decimalPad
            textField.text = text
            subscription = NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: textField)
                .map { ($0.object as? UITextField)?.text ?? "" }
                .assign(to: \.text, on: self)
        }

        // create a `Done` action that updates the `isPresented` binding when tapped
        // this is just for Demo only but we should really inject
        // an array of buttons (with their title, style and tap handler)
        let actionCancel = UIAlertAction(title: "button.cancel".localized, style: .default) { [weak self] _ in
            self?.isPresented?.wrappedValue = false
        }

        let actionConfirm = UIAlertAction(title: "button.confirm".localized, style: .default) { [weak self] _ in
            self?.amountChanged?(self?.text ?? "")
            self?.isPresented?.wrappedValue = false
        }
        vc.addAction(actionCancel)
        vc.addAction(actionConfirm)
        present(vc, animated: true, completion: nil)
    }
}

struct TextFieldAlert {
    // MARK: Properties

    let title: String
    let message: String?
    let initial: String
    var isPresented: Binding<Bool>? = nil
    var amountChanged: ((String) -> Void)? = nil

    // MARK: Modifiers

    func dismissable(_ isPresented: Binding<Bool>? = nil, _ amountChanged: ((String) -> Void)? = nil) -> TextFieldAlert {
        TextFieldAlert(title: title, message: message, initial: initial, isPresented: isPresented, amountChanged: amountChanged)
    }
}

extension TextFieldAlert: UIViewControllerRepresentable {
    typealias UIViewControllerType = TextFieldAlertViewController

    func makeUIViewController(context _: UIViewControllerRepresentableContext<TextFieldAlert>) -> UIViewControllerType {
        TextFieldAlertViewController(title: title, message: message, initial: initial, isPresented: isPresented, amountChanged: amountChanged)
    }

    func updateUIViewController(_: UIViewControllerType,
                                context _: UIViewControllerRepresentableContext<TextFieldAlert>)
    {
        // no update needed
    }
}

struct TextFieldWrapper<PresentingView: View>: View {
    @Binding var isPresented: Bool
    var amountChanged: ((String) -> Void)? = nil
    
    let presentingView: PresentingView
    let content: () -> TextFieldAlert

    var body: some View {
        ZStack {
            if isPresented { content().dismissable($isPresented, amountChanged) }
            presentingView
        }
    }
}

extension View {
    func textFieldAlert(isPresented: Binding<Bool>,
                        amountChanged: ((String) -> Void)?,
                        content: @escaping () -> TextFieldAlert) -> some View
    {
        TextFieldWrapper(isPresented: isPresented,
                         amountChanged: amountChanged,
                         presentingView: self,
                         content: content)
    }
}
