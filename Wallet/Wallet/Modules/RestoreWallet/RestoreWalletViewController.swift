import UIKit

class RestoreWalletViewController: UIViewController {

    let viewDelegate: RestoreWalletViewDelegate

    @IBOutlet weak var wordsTextView: UITextView?

    init(viewDelegate: RestoreWalletViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: RestoreWalletViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Restore Wallet"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelDidTap))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneDidTap))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func cancelDidTap() {
        viewDelegate.cancelDidTap()
    }

    @objc func doneDidTap() {

    }

}

extension RestoreWalletViewController: RestoreWalletViewProtocol {

}
