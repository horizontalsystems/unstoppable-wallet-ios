import UIKit
import GrouviExtensions
import GrouviHUD
import RxSwift
import RxCocoa

class KeyboardObservingViewController: UIViewController {

    let disposeBag = DisposeBag()

    var keyboardFrameDisposable: Disposable?

    var scrollView: UIScrollView { fatalError("Must be implemented by successor.") }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if keyboardFrameDisposable == nil {
            subscribeKeyboard()
        }
    }

    private func subscribeKeyboard() {
        updateUI(keyboardHeight: HUDKeyboardHelper.shared.visibleKeyboardHeight)

        keyboardFrameDisposable = NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillChangeFrame).subscribeDisposableAsync(disposeBag, onNext: { [weak self] notification in
            self?.onKeyboardFrameChange(notification)
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let disposable = keyboardFrameDisposable {
            disposable.dispose()
            keyboardFrameDisposable = nil
        }
    }

    func enableContent(enabled: Bool) {
    }

//Handle keyboard auto open/close

    func onKeyboardFrameChange(_ notification: Notification) {
        let screenKeyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let height = view.height + view.y
        let keyboardHeight = height - screenKeyboardFrame.origin.y

        let duration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let curve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue

        updateUI(keyboardHeight: keyboardHeight, duration: duration, options: UIViewAnimationOptions(rawValue: curve << 16))
    }

    func updateUI(keyboardHeight: CGFloat, duration: TimeInterval = 0.2, options: UIViewAnimationOptions = .curveLinear, completion: (() -> ())? = nil) {
    }

}
