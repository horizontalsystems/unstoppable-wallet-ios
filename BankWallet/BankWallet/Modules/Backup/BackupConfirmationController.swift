import UIKit
import ActionSheet
import SnapKit

class BackupConfirmationController: WalletViewController {

    let delegate: IBackupViewDelegate
    let indexes: [Int]

    let firstIndexedInputField = IndexedInputField()
    let secondIndexedInputField = IndexedInputField()

    let descriptionLabel = UILabel()

    init(indexes: [Int], delegate: IBackupViewDelegate) {
        self.indexes = indexes
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
        descriptionLabel.text = "backup.confirmation.description".localized
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

        firstIndexedInputField.indexLabel.text = "\(indexes[0])."
        secondIndexedInputField.indexLabel.text = "\(indexes[1])."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstIndexedInputField.textField.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func doneDidTap() {
        if let firstWord = firstIndexedInputField.textField.text?.lowercased(), let secondWord = secondIndexedInputField.textField.text?.lowercased() {
            delegate.validateDidClick(confirmationWords: [indexes[0]: firstWord, indexes[1]: secondWord])
        }
    }

    func showValidation(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
