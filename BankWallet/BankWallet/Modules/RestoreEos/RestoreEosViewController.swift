import UIKit
import SnapKit

class RestoreEosViewController: WalletViewController {
    let delegate: IRestoreEosViewDelegate

    let accountNameField = AddressInputField(frame: .zero, placeholder: "restore.placeholder.account_name".localized, showQrButton: false, canEdit: true, lineBreakMode: .byWordWrapping)
    let accountPrivateKeyField = AddressInputField(frame: .zero, placeholder: "restore.placeholder.private_key".localized, numberOfLines: 2, showQrButton: true, canEdit: false, lineBreakMode: .byWordWrapping)

    init(delegate: IRestoreEosViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "restore.title".localized

        view.addSubview(accountNameField)
        accountNameField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreTheme.bigMargin)
            maker.trailing.equalToSuperview().offset(-RestoreTheme.bigMargin)
            maker.top.equalTo(view.snp.topMargin).offset(RestoreTheme.smallMargin)
            maker.height.equalTo(RestoreTheme.accountNameHeight)
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
            maker.leading.equalToSuperview().offset(RestoreTheme.bigMargin)
            maker.trailing.equalToSuperview().offset(-RestoreTheme.bigMargin)
            maker.top.equalTo(accountNameField.snp.bottom).offset(RestoreTheme.mediumMargin)
            maker.height.equalTo(RestoreTheme.accountPrivateKeyHeight)
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(doneDidTap))

        delegate.viewDidLoad()
    }

    @objc func doneDidTap() {
        delegate.didTapDone()
    }

    @objc func cancelDidTap() {
        delegate.didTapCancel()
    }

    private func onScanQrCode() {
        let scanController = ScanQRController()
        scanController.onCodeParse = { [weak self] key in
            self?.delegate.onScan(key: key)
        }
        present(scanController, animated: true)
    }

}

extension RestoreEosViewController: IRestoreEosView {

    func showCancelButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(cancelDidTap))
    }

    func set(account: String?) {
        accountNameField.bind(address: account, error: nil)
    }

    func set(key: String?) {
        accountPrivateKeyField.bind(address: key, error: nil)
    }

}
