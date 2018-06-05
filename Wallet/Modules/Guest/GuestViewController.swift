import UIKit

class GuestViewController: UIViewController {

    let interactor: GuestInteractorProtocol

    init(interactor: GuestInteractorProtocol) {
        self.interactor = interactor

        super.init(nibName: String(describing: GuestViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func createNewWalletDidTap() {
        interactor.createNewWalletDidTap()
    }

    @IBAction func restoreWalletDidTap() {
        interactor.restoreWalletDidTap()
    }

}
