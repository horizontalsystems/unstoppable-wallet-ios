import UIKit
import GrouviActionSheet

class BackupConfirmationController: UIViewController {

    let delegate: IBackupViewDelegate
    let indexes: [Int]

    @IBOutlet weak var firstIndexedInputField: IndexedInputField?
    @IBOutlet weak var secondIndexedInputField: IndexedInputField?

    @IBOutlet weak var descriptionLabel: UILabel?

    init(indexes: [Int], delegate: IBackupViewDelegate) {
        self.indexes = indexes
        self.delegate = delegate

        super.init(nibName: String(describing: BackupConfirmationController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground

        title = "backup.confirmation.title".localized
        descriptionLabel?.text = "backup.confirmation.description".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "backup.confirmation.done_button".localized, style: .plain, target: self, action: #selector(doneDidTap))

        firstIndexedInputField?.textField.returnKeyType = .next
        firstIndexedInputField?.onReturn = { [weak self] in
            self?.secondIndexedInputField?.textField.becomeFirstResponder()
        }
        secondIndexedInputField?.textField.returnKeyType = .done
        secondIndexedInputField?.onReturn = { [weak self] in
            self?.doneDidTap()
        }

        firstIndexedInputField?.indexLabel.text = "\(indexes[0])."
        secondIndexedInputField?.indexLabel.text = "\(indexes[1])."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstIndexedInputField?.textField.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func doneDidTap() {
        if let firstWord = firstIndexedInputField?.textField.text?.lowercased(), let secondWord = secondIndexedInputField?.textField.text?.lowercased(), !firstWord.isEmpty, !secondWord.isEmpty {
            delegate.validateDidClick(confirmationWords: [indexes[0]: firstWord, indexes[1]: secondWord])
        }
    }

    func showConfirmAlert() {
        BackupConfirmationViewController.show(from: self) { [weak self] in
            self?.delegate.onConfirm()
        }
    }

    func showValidationFailure() {
        HudHelper.instance.showError(title: "backup.confirmation.failure_alert.text".localized)
    }

}
