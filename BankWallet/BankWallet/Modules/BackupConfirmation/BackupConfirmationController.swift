import UIKit
import ActionSheet
import SnapKit

class BackupConfirmationController: WalletViewController {

    let delegate: IBackupConfirmationViewDelegate

    let firstIndexedInputField = IndexedInputField()
    let secondIndexedInputField = IndexedInputField()

    let descriptionLabel = UILabel()

    init(delegate: IBackupConfirmationViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .plain, target: self, action: #selector(doneDidTap))
        title = "backup.confirmation.title".localized

        view.addSubview(descriptionLabel)
        descriptionLabel.text = delegate.description.localized
        descriptionLabel.font = BackupTheme.confirmLabelFont
        descriptionLabel.textColor = BackupTheme.confirmLabelColor
        descriptionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.snp.topMargin).offset(BackupTheme.confirmLabelTopMargin)
            maker.leading.equalToSuperview().offset(BackupTheme.confirmSideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.confirmSideMargin)
        }

        view.addSubview(firstIndexedInputField)
        firstIndexedInputField.textField.returnKeyType = .next
        firstIndexedInputField.onReturn = { [weak self] in
            self?.secondIndexedInputField.textField.becomeFirstResponder()
        }
        firstIndexedInputField.cornerRadius = BackupTheme.buttonCornerRadius
        firstIndexedInputField.borderColor = BackupTheme.inputBorderColor
        firstIndexedInputField.borderWidth = 1 / UIScreen.main.scale
        firstIndexedInputField.snp.makeConstraints { maker in
            maker.top.equalTo(self.descriptionLabel.snp.bottom).offset(BackupTheme.wordsBottomMargin)
            maker.leading.equalToSuperview().offset(BackupTheme.confirmSideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.confirmSideMargin)
            maker.height.equalTo(BackupTheme.confirmInputHeight)
        }

        view.addSubview(secondIndexedInputField)
        secondIndexedInputField.textField.returnKeyType = .done
        secondIndexedInputField.onReturn = { [weak self] in
            self?.doneDidTap()
        }
        secondIndexedInputField.cornerRadius = BackupTheme.buttonCornerRadius
        secondIndexedInputField.borderColor = BackupTheme.inputBorderColor
        secondIndexedInputField.borderWidth = 1 / UIScreen.main.scale
        secondIndexedInputField.snp.makeConstraints { maker in
            maker.top.equalTo(self.firstIndexedInputField.snp.bottom).offset(BackupTheme.wordsBottomMargin)
            maker.leading.equalToSuperview().offset(BackupTheme.confirmSideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.confirmSideMargin)
            maker.height.equalTo(BackupTheme.confirmInputHeight)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateInputFields()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return App.theme.statusBarStyle
    }

    private func updateInputFields() {
        delegate.generateNewIndexes()

        firstIndexedInputField.indexLabel.text = "\(delegate.indexes[0])."
        secondIndexedInputField.indexLabel.text = "\(delegate.indexes[1])."

        firstIndexedInputField.textField.becomeFirstResponder()
    }

    @objc func doneDidTap() {
        if let firstWord = firstIndexedInputField.textField.text?.lowercased(), let secondWord = secondIndexedInputField.textField.text?.lowercased() {
            delegate.validateDidClick(confirmationWords: [firstWord, secondWord])
        }
    }

}

extension BackupConfirmationController: IBackupConfirmationView {

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    func onBecomeActive() {
        updateInputFields()
    }

}
