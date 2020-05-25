import UIKit
import ActionSheet
import SnapKit
import ThemeKit

class BackupConfirmationController: ThemeViewController {

    let delegate: IBackupConfirmationViewDelegate

    let firstIndexedInputField = IndexedInputField()
    let secondIndexedInputField = IndexedInputField()

    let descriptionLabel = UILabel()

    init(delegate: IBackupConfirmationViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .plain, target: self, action: #selector(doneDidTap))
        title = "backup.confirmation.title".localized

        view.addSubview(firstIndexedInputField)
        firstIndexedInputField.snp.makeConstraints { maker in
            maker.top.equalTo(self.view.snp.topMargin).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        firstIndexedInputField.textField.returnKeyType = .next
        firstIndexedInputField.onReturn = { [weak self] in
            self?.secondIndexedInputField.textField.becomeFirstResponder()
        }
        firstIndexedInputField.cornerRadius = CGFloat.cornerRadius2x
        firstIndexedInputField.borderColor = .themeSteel20
        firstIndexedInputField.borderWidth = 1 / UIScreen.main.scale

        view.addSubview(secondIndexedInputField)
        secondIndexedInputField.snp.makeConstraints { maker in
            maker.top.equalTo(self.firstIndexedInputField.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        secondIndexedInputField.textField.returnKeyType = .done
        secondIndexedInputField.onReturn = { [weak self] in
            self?.doneDidTap()
        }
        secondIndexedInputField.cornerRadius = CGFloat.cornerRadius2x
        secondIndexedInputField.borderColor = .themeSteel20
        secondIndexedInputField.borderWidth = 1 / UIScreen.main.scale

        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.secondIndexedInputField.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }
        descriptionLabel.text = "backup.words.confirmation_description".localized(delegate.predefinedAccountTitle)
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateInputFields()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        HudHelper.instance.showError(title: error.smartDescription)
    }

    func onBecomeActive() {
        updateInputFields()
    }

}
