import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit

class WalletConnectShowSigningMessageViewController: ThemeViewController {
    private let viewModel: WalletConnectSignMessageRequestViewModel

    private let textView = UITextView.appDebug
    private let bottomWrapper = BottomGradientHolder()

    private let signButton = ThemeButton()
    private let rejectButton = ThemeButton()

    private var message: String?

    init(viewModel: WalletConnectSignMessageRequestViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.sign.request_title".localized

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(textView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        bottomWrapper.addSubview(signButton)
        signButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        signButton.apply(style: .primaryYellow)
        signButton.setTitle("button.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        bottomWrapper.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(signButton.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        rejectButton.apply(style: .primaryGray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.text = viewModel.message
    }

    @objc private func onTapSign() {
        do {
            try viewModel.sign()
            dismiss(animated: true)
        } catch {
            HudHelper.instance.showError(title: error.localizedDescription)
        }
    }

    @objc private func onTapReject() {
        viewModel.reject()
        dismiss(animated: true)
    }

}
