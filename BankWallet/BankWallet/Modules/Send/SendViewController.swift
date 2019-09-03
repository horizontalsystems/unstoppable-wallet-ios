import UIKit
import RxSwift
import SnapKit

class SendViewController: UIViewController {
    private let disposeBag = DisposeBag()

    private let delegate: ISendViewDelegate

    private let iconImageView = UIImageView()
    private let sendHolderView = UIView()
    private let sendButton = RespondButton()

    private let views: [UIView]

    init(delegate: ISendViewDelegate, views: [UIView]) {
        self.delegate = delegate
        self.views = views

        super.init(nibName: nil, bundle: nil)

        sendHolderView.addSubview(sendButton)
        sendHolderView.backgroundColor = .clear
        sendHolderView.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.sendButtonHolderHeight)
        }
        sendButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(SendTheme.margin)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(SendTheme.sendButtonHeight)
        }
        sendButton.onTap = { [weak self] in
            self?.delegate.onProceedClicked()
        }
        sendButton.backgrounds = ButtonTheme.yellowBackgroundDictionary
        sendButton.textColors = ButtonTheme.textColorDictionary
        sendButton.titleLabel.text = "send.next_button".localized
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

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
        var lastView: UIView?
        for view in views {
            add(view: view, lastView: lastView)
            lastView = view
        }

        add(view: sendHolderView, lastView: lastView)
    }

    private func add(view: UIView, lastView: UIView?) {
        self.view.addSubview(view)
        if let lastView = lastView {
            view.snp.makeConstraints { maker in
                maker.leading.equalToSuperview()
                maker.trailing.equalToSuperview()
                maker.top.equalTo(lastView.snp.bottom)
            }
        } else {
            view.snp.makeConstraints { maker in
                maker.top.equalTo(self.view.snp.topMargin)
                maker.leading.equalToSuperview()
                maker.trailing.equalToSuperview()
            }
        }
    }


}

extension SendViewController: ISendView {

    func set(coin: Coin) {
        title = "send.title".localized(coin.code)
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

    func set(sendButtonEnabled: Bool) {
        sendButton.state = sendButtonEnabled ? .active : .disabled
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func dismissWithSuccess() {
        navigationController?.dismiss(animated: true)
        HudHelper.instance.showSuccess()
    }

}
