import UIKit

class RestoreWalletViewController: UIViewController {

    let viewDelegate: RestoreWalletViewDelegate

    init(viewDelegate: RestoreWalletViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: RestoreWalletViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func cancelDidTap() {
        viewDelegate.cancelDidTap()
    }

}

extension RestoreWalletViewController: RestoreWalletViewProtocol {

}
