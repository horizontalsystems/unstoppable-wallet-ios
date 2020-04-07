import UIKit
import SnapKit
import ThemeKit

class RestoreEosViewController: ThemeViewController {
    private let delegate: IRestoreEosViewDelegate

    private let accountNameField = AddressInputField(frame: .zero, placeholder: "restore.placeholder.account_name".localized, showQrButton: false, canEdit: true, lineBreakMode: .byWordWrapping)
    private let accountPrivateKeyField = AddressInputField(frame: .zero, placeholder: "restore.placeholder.private_key".localized, numberOfLines: 2, showQrButton: true, canEdit: false, lineBreakMode: .byWordWrapping)

    init(delegate: IRestoreEosViewDelegate) {
        self.delegate = delegate

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

        view.addSubview(accountNameField)
        accountNameField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(view.snp.topMargin).offset(CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightSingleLineInput)
        }
        accountNameField.onPaste = { [weak self] in
            self?.delegate.onPasteAccountClicked()
        }
        accountNameField.onDelete = { [weak self] in
            self?.delegate.onDeleteAccount()
        }
        accountNameField.onTextChange = { [weak self] text in
            self?.delegate.onChange(account: text)
        }

        view.addSubview(accountPrivateKeyField)
        accountPrivateKeyField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(accountNameField.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightDoubleLineInput)
        }
        accountPrivateKeyField.onPaste = { [weak self] in
            self?.delegate.onPasteKeyClicked()
        }
        accountPrivateKeyField.onScan = { [weak self] in
            self?.onScanQrCode()
        }
        accountPrivateKeyField.onDelete = { [weak self] in
            self?.delegate.onDeleteKey()
        }

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async  {
            self.accountNameField.becomeFirstResponder()
        }
    }

    @objc func doneDidTap() {
        delegate.didTapDone()
    }

    @objc func cancelDidTap() {
        delegate.didTapCancel()
    }

    private func onScanQrCode() {
        let scanController = ScanQRController(delegate: self)
        present(scanController, animated: true)
    }

}

extension RestoreEosViewController: IRestoreEosView {

    func showNextButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(doneDidTap))
    }

    func showRestoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(doneDidTap))
    }

    func set(account: String?) {
        accountNameField.bind(address: account, error: nil)
    }

    func set(key: String?) {
        accountPrivateKeyField.bind(address: key, error: nil)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}

extension RestoreEosViewController: IScanQrCodeDelegate {

    func didScan(string: String) {
        delegate.onScan(key: string)
    }

}
