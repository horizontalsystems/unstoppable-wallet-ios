import UIKit
import SnapKit

class SendConfirmationViewController: UIViewController {
    private let delegate: ISendConfirmationViewDelegate

    private let sendHolderView = UIView()
    private let sendButton = RespondButton()

    private let views: [UIView]

    init(delegate: ISendConfirmationViewDelegate, views: [UIView]) {
        self.delegate = delegate
        self.views = views

        super.init(nibName: nil, bundle: nil)

        title = "send.confirmation.title".localized

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
            self?.delegate.onSendClicked()
        }
        sendButton.backgrounds = ButtonTheme.yellowBackgroundDictionary
        sendButton.textColors = ButtonTheme.textColorDictionary
        sendButton.titleLabel.text = "send.confirmation.send_button".localized
        sendButton.cornerRadius = SendTheme.sendButtonCornerRadius
    }

    @objc func onClose() {
//        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground

        buildViews()
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

extension SendConfirmationViewController: ISendConfirmationView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

}
