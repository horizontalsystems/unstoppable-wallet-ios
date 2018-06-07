import UIKit

class BackupWalletConfirmationController: UIViewController {

    let viewDelegate: BackupWalletViewDelegate
    let indexes: [Int]

    @IBOutlet weak var firstIndexLabel: UILabel?
    @IBOutlet weak var secondIndexLabel: UILabel?
    @IBOutlet weak var firstTextField: UITextField?
    @IBOutlet weak var secondTextField: UITextField?

    init(indexes: [Int], viewDelegate: BackupWalletViewDelegate) {
        self.indexes = indexes
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupWalletConfirmationController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        firstIndexLabel?.text = "\(indexes[0])."
        secondIndexLabel?.text = "\(indexes[1])."
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func confirmDidTap() {
        if let firstWord = firstTextField?.text, let secondWord = secondTextField?.text {
            viewDelegate.validateDidTap(confirmationWords: [indexes[0]: firstWord, indexes[1]: secondWord])
        }
    }

    @IBAction func backDidTap() {
        viewDelegate.hideConfirmationDidTap()
    }

    func showValidationFailure() {
        let alert = UIAlertController(title: "Validation Failure", message: "Entered words do not match", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
