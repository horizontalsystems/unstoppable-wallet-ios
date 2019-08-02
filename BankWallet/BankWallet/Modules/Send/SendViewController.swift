import UIKit
import RxSwift
import SnapKit

class SendViewController: UIViewController {
    private let disposeBag = DisposeBag()

    private let delegate: ISendViewDelegate

    private let iconImageView = UIImageView()
    private let sendButton = RespondButton()

    private let views: [UIView]
    private var lastView: UIView?

    init(delegate: ISendViewDelegate, views: [UIView]) {
        self.delegate = delegate
        self.views = views

        super.init(nibName: nil, bundle: nil)

        sendButton.onTap = { [weak self] in
            self?.delegate.onSendClicked()
        }
        sendButton.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.sendButtonHeight)
        }

        sendButton.backgrounds = ButtonTheme.yellowBackgroundDictionary
        sendButton.textColors = ButtonTheme.textColorDictionary
        sendButton.titleLabel.text = "send.confirmation.send_button".localized
        sendButton.cornerRadius = SendTheme.sendButtonCornerRadius
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

        sendButton.state = .disabled

        buildViews()

        delegate.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate.showKeyboard()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    private func buildViews() {
        for view in views {
            add(view: view)
        }

        add(view: sendButton, offset: SendTheme.margin)
    }

    private func add(view: UIView, offset: CGFloat = 0) {
        self.view.addSubview(view)
        if let lastView = lastView {
            view.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().offset(offset)
                maker.trailing.equalToSuperview().offset(-offset)
                maker.top.equalTo(lastView.snp.bottom)
            }
        } else {
            view.snp.makeConstraints { maker in
                maker.top.equalTo(self.view.snp.topMargin)
                maker.leading.equalToSuperview().offset(offset)
                maker.trailing.equalToSuperview().offset(-offset)
            }
        }
        lastView = view
        self.view.layoutIfNeeded()
    }


}

extension SendViewController: ISendView {

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

    func showConfirmation(viewItem: SendConfirmationViewItem) {
        let confirmationController = SendConfirmationViewController(delegate: delegate, viewItem: viewItem)
        present(confirmationController, animated: true)
    }

    func showProgress() {
        HudHelper.instance.showSpinner(userInteractionEnabled: false)
    }

    func set(sendButtonEnabled: Bool) {
        sendButton.state = sendButtonEnabled ? .active : .disabled
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func dismissWithSuccess() {

        presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.view.endEditing(true)
            self?.dismiss(animated: true)
        })
        HudHelper.instance.showSuccess()
    }

}
