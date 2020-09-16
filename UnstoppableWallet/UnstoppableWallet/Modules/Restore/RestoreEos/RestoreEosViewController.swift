import ThemeKit
import RxSwift
import RxCocoa

class RestoreEosViewController: ThemeViewController {
    private let restoreView: RestoreView
    private let viewModel: RestoreEosViewModel

    private let accountNameField = InputField()
    private let accountPrivateKeyField = InputField()

    private let disposeBag = DisposeBag()

    init(restoreView: RestoreView, viewModel: RestoreEosViewModel) {
        self.restoreView = restoreView
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.enter_key".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "button.back".localized, style: .plain, target: nil, action: nil)

        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
        }

        if restoreView.viewModel.selectCoins {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(proceedDidTap))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(proceedDidTap))
        }

        view.addSubview(accountNameField)
        accountNameField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(view.snp.topMargin).offset(CGFloat.margin3x)
        }

        accountNameField.placeholder = "restore.placeholder.account_name".localized
        accountNameField.onTextChange = { [weak self] text in
            self?.viewModel.onEnter(account: text ?? "")
        }

        view.addSubview(accountPrivateKeyField)
        accountPrivateKeyField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(accountNameField.snp.bottom).offset(CGFloat.margin4x)
        }

        accountPrivateKeyField.placeholder = "restore.placeholder.private_key".localized
        accountPrivateKeyField.showQrButton = true
        accountPrivateKeyField.canEdit = false
        accountPrivateKeyField.openScan = { [weak self] scanController in
            self?.present(scanController, animated: true)
        }
        accountPrivateKeyField.onTextChange = { [weak self] text in
            self?.viewModel.onEnter(privateKey: text ?? "")
        }

        accountNameField.bind(text: viewModel.account, error: nil)
        accountPrivateKeyField.bind(text: viewModel.privateKey, error: nil)

        viewModel.accountTypeSignal
                .emit(onNext: { [weak self] accountType in
                    self?.restoreView.viewModel.onEnter(accountType: accountType)
                })
                .disposed(by: disposeBag)

        viewModel.errorSignal
                .emit(onNext: { error in
                    HudHelper.instance.showError(title: error.localizedDescription)
                })
                .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async  {
            self.accountNameField.becomeFirstResponder()
        }
    }

    @objc private func proceedDidTap() {
        viewModel.onProceed()
    }

    @objc private func cancelDidTap() {
        dismiss(animated: true)
    }

}
