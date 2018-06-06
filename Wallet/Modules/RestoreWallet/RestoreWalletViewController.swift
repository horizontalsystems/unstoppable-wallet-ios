import UIKit

class RestoreWalletViewController: UIViewController, RestoreWalletViewProtocol {

    let delegate: RestoreWalletViewDelegate

    init(delegate: RestoreWalletViewDelegate) {
        self.delegate = delegate

        super.init(nibName: String(describing: RestoreWalletViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func cancelDidTap() {
        delegate.cancelDidTap()
    }

}
