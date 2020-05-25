import UIKit
import UIExtensions
import HUD
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

        keyboardFrameDisposable = NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                self?.onKeyboardFrameChange(notification)
            })
        keyboardFrameDisposable?.disposed(by: disposeBag)
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
        let screenKeyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let height = view.height + view.y
        let keyboardHeight = height - screenKeyboardFrame.origin.y

        let duration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let curve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue

        updateUI(keyboardHeight: keyboardHeight, duration: duration, options: UIView.AnimationOptions(rawValue: curve << 16))
    }

    func updateUI(keyboardHeight: CGFloat, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = .curveLinear, completion: (() -> ())? = nil) {
    }

}
