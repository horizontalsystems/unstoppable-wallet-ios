import UIKit
import RxSwift
import SnapKit
import ThemeKit
import MarketKit
import ComponentKit

class SendViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let delegate: ISendViewDelegate

    private let scrollView = UIScrollView()
    private let container = UIView()
    private let iconImageView = UIImageView()
    private let sendHolderView = UIView()
    private let sendButton = ThemeButton()
    private var keyboardShown = false

    private let views: [UIView]

    init(delegate: ISendViewDelegate, views: [UIView]) {
        self.delegate = delegate
        self.views = views

        super.init()

        sendHolderView.addSubview(sendButton)

        sendHolderView.backgroundColor = .clear
        sendHolderView.snp.makeConstraints { maker in
            maker.height.equalTo(66)
        }

        sendButton.apply(style: .primaryYellow)
        sendButton.setTitle("send.next_button".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onSendTouchUp), for: .touchUpInside)

        sendButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(50)
        }
    }

    @objc func onClose() {
        delegate.onClose()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view)
            maker.top.bottom.equalTo(self.scrollView)
        }

        iconImageView.tintColor = .themeGray

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        sendButton.isEnabled = false

        buildViews()

        delegate.onViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !keyboardShown {
            keyboardShown = true
            delegate.showKeyboard()
        }
    }

    private func buildViews() {
        var lastView: UIView?
        for view in views {
            add(view: view, lastView: lastView)
            lastView = view
        }

        add(view: sendHolderView, lastView: lastView, last: true)
    }

    private func add(view: UIView, lastView: UIView?, last: Bool = false) {
        container.addSubview(view)
        if let lastView = lastView {
            view.snp.makeConstraints { maker in
                maker.leading.equalTo(self.view.snp.leading)
                maker.trailing.equalTo(self.view.snp.trailing)
                maker.top.equalTo(lastView.snp.bottom)
                if last {
                    maker.bottom.equalToSuperview()
                }
            }
        } else {
            view.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.leading.equalTo(self.view.snp.leading)
                maker.trailing.equalTo(self.view.snp.trailing)
                if last {
                    maker.bottom.equalToSuperview()
                }
            }
        }
    }

    @objc private func onSendTouchUp() {
        delegate.onProceedClicked()
    }

}

extension SendViewController: ISendView {

    func set(coin: Coin, coinType: CoinType) {
        title = "send.title".localized(coin.code)
        iconImageView.setImage(withUrlString: coin.imageUrl, placeholder: UIImage(named: coinType.placeholderImageName))
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

    func showProgress() {
        HudHelper.instance.showSpinner(userInteractionEnabled: false)
    }

    func set(actionState: SendPresenter.ActionState) {
        let defaultTitle = "send.next_button".localized

        switch actionState {
        case .enabled:
            sendButton.isEnabled = true
            sendButton.setTitle(defaultTitle, for: .normal)
        case .disabled(let error):
            sendButton.isEnabled = false
            sendButton.setTitle(error ?? defaultTitle, for: .normal)
        }
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func dismissWithSuccess() {
        navigationController?.dismiss(animated: true)
        HudHelper.instance.showSuccess(title: "alert.success_action".localized)
    }

}
