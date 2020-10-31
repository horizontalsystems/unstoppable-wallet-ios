import UIKit
import ThemeKit
import RxSwift
import RxCocoa

protocol IVerifiedInputViewModel {
    var canEdit: Bool { get }
    var maximumNumberOfLines: Int { get }
    var buttonItems: [InputFieldButtonItem] { get }

    var onChangeText: ((String) -> ())? { get }
    var isValidText: ((String) -> Bool)? { get }
    var onChangeHeight: ((CGFloat) -> ())? { get }
    
    var placeholderDriver: Driver<String> { get }
    var errorDriver: Driver<String?> { get }
    var errorColorDriver: Driver<UIColor> { get }
}

extension IVerifiedInputViewModel {
    var canEdit: Bool { true }
    var maximumNumberOfLines: Int { 1 }
    var buttonItems: [InputFieldButtonItem] { [] }
}

class VerifiedInputCell: UITableViewCell {
    private static let margin = CGFloat.margin4x
    private static let stackInsideMargin = CGFloat.margin2x
    private static let errorFont = UIFont.subhead2
    private static let errorMargin = CGFloat.margin1x
    private static let spacing = CGFloat.margin1x

    private let verticalStackView = UIStackView()

    private let inputFieldView = InputFieldStackView()
    private let errorLabelWrapper = UIView()
    private let errorLabel = UILabel()

    private let disposeBag = DisposeBag()

    init(viewModel: IVerifiedInputViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(Self.margin)
        }

        verticalStackView.axis = .vertical
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.layoutMargins = UIEdgeInsets(top: Self.stackInsideMargin, left: Self.stackInsideMargin, bottom: Self.stackInsideMargin, right: Self.stackInsideMargin)
        verticalStackView.backgroundColor = .themeLawrence
        verticalStackView.layer.cornerRadius = .cornerRadius2x
        verticalStackView.layer.borderWidth = CGFloat.heightOnePixel
        verticalStackView.layer.borderColor = UIColor.themeSteel20.cgColor

        verticalStackView.addArrangedSubview(inputFieldView)
        verticalStackView.addArrangedSubview(errorLabelWrapper)
        verticalStackView.spacing = Self.spacing

        inputFieldView.canEdit = viewModel.canEdit
        inputFieldView.maximumNumberOfLines = viewModel.maximumNumberOfLines
        inputFieldView.append(items: viewModel.buttonItems)
        inputFieldView.onChangeText = viewModel.onChangeText
        inputFieldView.isValidText = viewModel.isValidText
        inputFieldView.onChangeHeight = viewModel.onChangeHeight

        errorLabelWrapper.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(Self.errorMargin)
        }

        errorLabel.font = Self.errorFont
        errorLabel.numberOfLines = 0
        errorLabelWrapper.isHidden = true

        subscribe(disposeBag, viewModel.placeholderDriver) { [weak self] in self?.inputFieldView.set(placeholder: $0) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] in self?.set(error: $0) }
        subscribe(disposeBag, viewModel.errorColorDriver) { [weak self] in self?.errorLabel.textColor = $0 }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func set(error: String?) {
        errorLabelWrapper.isHidden = error == nil
        errorLabel.text = error
    }

}

extension VerifiedInputCell {

    public var inputText: String {
        inputFieldView.inputText
    }

    override func becomeFirstResponder() -> Bool {
        inputFieldView.becomeFirstResponder()
    }

}

extension VerifiedInputCell {

    static func height(containerWidth: CGFloat, text: String, buttonItems: [InputFieldButtonItem], maximumNumberOfLines: Int, error: String?) -> CGFloat {
        let stackContentWidth = containerWidth - 2 * Self.margin - 2 * Self.stackInsideMargin

        var height = InputFieldStackView
                .height(containerWidth: stackContentWidth,
                text: text,
                buttonItems: buttonItems,
                maximumNumberOfLines: maximumNumberOfLines)

        if let error = error {
            let errorHeight = error.height(forContainerWidth: stackContentWidth, font: Self.errorFont)

            height += errorHeight + Self.spacing
        }

        return height + 2 * Self.stackInsideMargin
    }

}
