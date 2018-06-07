import UIKit

class GuestViewController: UIViewController {

    let viewDelegate: GuestViewDelegate

    init(viewDelegate: GuestViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: GuestViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func createNewWalletDidTap() {
        viewDelegate.createNewWalletDidTap()
    }

    @IBAction func restoreWalletDidTap() {
        viewDelegate.restoreWalletDidTap()
    }

}
