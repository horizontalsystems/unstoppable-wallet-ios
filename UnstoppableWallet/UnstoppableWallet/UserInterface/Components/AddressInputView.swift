import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class AddressInputView: UIView {
    private let formValidatedView: FormValidatedView
    private let inputStackView = InputStackView()

    private let stateView = InputStateWrapperView()

    private let deleteView = InputSecondaryCircleButtonWrapperView()
    private let scanView = InputSecondaryCircleButtonWrapperView()
    private let pasteView = InputSecondaryButtonWrapperView(style: .default)

    var onChangeText: ((String?) -> ())?
    var onFetchText: ((String?) -> ())?
    var onOpenViewController: ((UIViewController) -> ())?

    init() {
        formValidatedView = FormValidatedView(contentView: inputStackView, padding: UIEdgeInsets(top: 0, left: .margin16, bottom: 0, right: .margin16))

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(formValidatedView)
        formValidatedView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stateView.isSpinnerVisible = false
        stateView.isSuccessVisible = false

        deleteView.button.set(image: UIImage(named: "trash_20"))
        deleteView.onTapButton = { [weak self] in self?.onTapDelete() }

        scanView.button.set(image: UIImage(named: "qr_scan_20"))
        scanView.onTapButton = { [weak self] in self?.onTapScan() }

        pasteView.button.setTitle("button.paste".localized, for: .normal)
        pasteView.onTapButton = { [weak self] in self?.onTapPaste() }
        pasteView.button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        inputStackView.autocapitalizationType = .none
        inputStackView.autocorrectionType = .no

        inputStackView.appendSubview(stateView)
        inputStackView.appendSubview(deleteView)
        inputStackView.appendSubview(scanView)
        inputStackView.appendSubview(pasteView)

        inputStackView.onChangeText = { [weak self] text in
            self?.handleChange(text: text)
        }

        syncButtonStates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTapDelete() {
        inputStackView.text = nil
        handleChange(text: nil)
    }

    private func onTapScan() {
        let scanQrViewController = ScanQrViewController()
        scanQrViewController.delegate = self
        onOpenViewController?(scanQrViewController)
    }

    private func onTapPaste() {
        guard let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") else {
            return
        }

        onFetchText?(text)
    }

    private func handleChange(text: String?) {
        onChangeText?(text)
        syncButtonStates()
    }

    private func syncButtonStates() {
        if let text = inputStackView.text, !text.isEmpty {
            deleteView.isHidden = false
            pasteView.isHidden = true
            scanView.isHidden = true
        } else {
            deleteView.isHidden = true
            pasteView.isHidden = false
            scanView.isHidden = false
        }
    }

}

extension AddressInputView {

    var inputPlaceholder: String? {
        get { inputStackView.placeholder }
        set { inputStackView.placeholder = newValue }
    }

    var inputText: String? {
        get { inputStackView.text }
        set {
            inputStackView.text = newValue
            syncButtonStates()
        }
    }

    var isEditable: Bool {
        get { inputStackView.isEditable }
        set { inputStackView.isEditable = newValue }
    }

    func set(cautionType: CautionType?) {
        formValidatedView.set(cautionType: cautionType)
    }

    func set(isSuccess: Bool) {
        stateView.isSuccessVisible = isSuccess
    }

    func set(isLoading: Bool) {
        stateView.isSpinnerVisible = isLoading
    }

    var onChangeEditing: ((Bool) -> ())? {
        get { inputStackView.onChangeEditing }
        set { inputStackView.onChangeEditing = newValue }
    }

    var onChangeHeight: (() -> ())? {
        get { formValidatedView.onChangeHeight }
        set { formValidatedView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        formValidatedView.height(containerWidth: containerWidth)
    }

}

extension AddressInputView: IScanQrViewControllerDelegate {

    func didScan(viewController: UIViewController, string: String) {
        onFetchText?(string)
    }

}
