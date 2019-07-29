import UIKit
import RxSwift
import SnapKit

class SendNewViewController: UIViewController {
    private let disposeBag = DisposeBag()

    private let delegate: ISendViewDelegate

    private var keyboardFrameDisposable: Disposable?

    let iconImageView = UIImageView()

    init(delegate: ISendViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    @objc func onClose() {
        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground

        iconImageView.tintColor = .cryptoGray

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Close Full Transaction Icon"), style: .plain, target: self, action: #selector(onClose))

        delegate.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate.showKeyboard()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

//    private func subscribeKeyboard() {
//        keyboardFrameDisposable = NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] notification in
//                    self?.onKeyboardFrameChange(notification)
//                })
//        keyboardFrameDisposable?.disposed(by: disposeBag)
//    }
//
//    private func onKeyboardFrameChange(_ notification: Notification) {
//        let screenKeyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
//        let height = view.height + view.y
//        let keyboardHeight = height - screenKeyboardFrame.origin.y
//
//        let duration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
//        let curve = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue
//
//        updateUI(keyboardHeight: keyboardHeight, duration: duration, options: UIView.AnimationOptions(rawValue: curve << 16))
//    }
//
//    private func updateUI(keyboardHeight: CGFloat, duration: TimeInterval, options: UIView.AnimationOptions, completion: (() -> ())? = nil) {
//        var insets: UIEdgeInsets = tableView.contentInset
//        insets.bottom = keyboardHeight + RestoreTheme.listBottomMargin
//        tableView.contentInset = insets
//    }

}

extension SendNewViewController: ISendView {

    func build(modules: [ISendModule]) {
        var lastView: UIView?
        modules.forEach { module in
            view.addSubview(module.view)
            if let lastView = lastView {
                module.view.snp.makeConstraints { maker in
                    maker.left.right.equalToSuperview()
                    maker.top.equalTo(lastView.snp.bottom)
                    maker.height.equalTo(module.height)
                }
            } else {
                module.view.snp.makeConstraints { maker in
                    maker.top.equalTo(view.snp.topMargin)
                    maker.left.right.equalToSuperview()
                    maker.height.equalTo(module.height)
                }
            }
            lastView = module.view
            module.viewDidLoad()
        }
    }

    func set(coin: Coin) {
        title = "send.title".localized(coin.title)
        iconImageView.image = UIImage(named: "\(coin.code.lowercased())")?.withRenderingMode(.alwaysTemplate)
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func showProgress() {
        HudHelper.instance.showSpinner(userInteractionEnabled: false)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func dismissWithSuccess() {
        presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.dismiss(animated: true)
        })
        HudHelper.instance.showSuccess()
    }

}
