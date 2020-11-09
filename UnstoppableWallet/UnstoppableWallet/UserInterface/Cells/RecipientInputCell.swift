import UIKit
import ThemeKit
import RxSwift
import RxCocoa

protocol IPresentControllerDelegate: AnyObject {
    func open(viewController: UIViewController)
}

class RecipientInputCell: VerifiedInputCell {
    private let disposeBag = DisposeBag()
    weak var openDelegate: IPresentControllerDelegate?

    override init(viewModel: IVerifiedInputViewModel) {
        super.init(viewModel: viewModel)

        let buttons = [
            InputFieldButtonItem(style: .secondaryIcon, icon: UIImage(named: "Send Scan Icon"), visible: .onEmpty) { [weak self] in
                self?.onScanTapped()
            },
            InputFieldButtonItem(style: .secondaryDefault, title: "button.paste".localized, visible: .onEmpty) { [weak self] in
                self?.onPasteTapped()
        }]

        append(items: buttons)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onScanTapped() {
        let scanQrViewController = ScanQrViewController()
        scanQrViewController.delegate = self
        openDelegate?.open(viewController: scanQrViewController)
    }

    private func onPasteTapped() {
        guard let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") else {
            return
        }
        inputFieldText = text
        viewModel.inputFieldDidChange(text: text)
    }

}

extension RecipientInputCell: IScanQrViewControllerDelegate {

    func didScan(string: String) {
        inputFieldText = string
        viewModel.inputFieldDidChange(text: string)
    }

}
