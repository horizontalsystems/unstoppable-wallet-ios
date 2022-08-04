import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit
import RxSwift

class WalletConnectShowSigningMessageViewController: ThemeViewController {
    private let viewModel: WalletConnectSignMessageRequestViewModel

    private let disposeBag = DisposeBag()

    private let textView = UITextView.appDebug
    private let bottomWrapper = BottomGradientHolder()

    private let signButton = PrimaryButton()
    private let rejectButton = PrimaryButton()

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
        }

        signButton.set(style: .yellow)
        signButton.setTitle("button.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        bottomWrapper.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(signButton.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        rejectButton.set(style: .gray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        subscribe(disposeBag, viewModel.errorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.dismissSignal) { [weak self] in self?.dismiss() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.text = viewModel.message
    }

    @objc private func onTapSign() {
        viewModel.onSign()
    }

    @objc private func onTapReject() {
        viewModel.onReject()
    }

    private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.localizedDescription))
    }

    private func dismiss() {
        dismiss(animated: true)
    }

}
