import Foundation
import UIKit
import ThemeKit
import ComponentKit

protocol IWalletConnectErrorDelegate: AnyObject {
    func onDismiss()
}

class WalletConnectErrorViewController: ThemeViewController {
    private let error: String

    private let errorView = PlaceholderViewModule.reachabilityView()
    private let closeButton = PrimaryButton()

    weak var delegate: IWalletConnectErrorDelegate?

    init(error: String) {
        self.error = error

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.title".localized

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.text = error
        errorView.image = UIImage(named: "not_available_48")

        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(errorView.snp.bottom)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin24)
        }

        closeButton.set(style: .gray)
        closeButton.setTitle("button.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        delegate?.onDismiss()
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

}
