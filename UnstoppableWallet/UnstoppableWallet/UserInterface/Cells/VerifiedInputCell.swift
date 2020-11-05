import UIKit
import ThemeKit
import RxSwift
import RxCocoa

struct Caution {
    let text: String
    let type: CautionType
}

enum CautionType {
    case error
    case warning

    var color: UIColor {
        switch self {
        case .error: return .themeLucian
        case .warning: return .themeJacob
        }
    }

}

protocol IVerifiedInputViewModel {
    var inputFieldMaximumNumberOfLines: Int { get }
    var inputFieldCanEdit: Bool { get }
    var decimalKeyboard: Bool { get }

    var inputFieldButtonItems: [InputFieldButtonItem] { get }
    var inputFieldInitialValue: String? { get }
    var inputFieldPlaceholder: String? { get }

    func inputFieldDidChange(text: String)
    func inputFieldIsValid(text: String) -> Bool

    var inputFieldCautionDriver: Driver<Caution?> { get }
}

extension IVerifiedInputViewModel {
    var inputFieldCanEdit: Bool { true }
    var decimalKeyboard: Bool { true }
    var inputFieldKeyBoardType: Int { 1 }
    var inputFieldMaximumNumberOfLines: Int { 1 }
    var inputFieldButtonItems: [InputFieldButtonItem] { [] }
    var inputFieldInitialValue: String? { nil }
    var inputFieldPlaceholder: String? { nil }
}

class VerifiedInputCell: UITableViewCell {
    private static let margin = CGFloat.margin4x
    private static let stackInsideMargin = CGFloat.margin2x
    private static let cautionFont = UIFont.subhead2
    private static let cautionMargin = CGFloat.margin1x
    private static let spacing = CGFloat.margin1x

    private let verticalStackView = UIStackView()

    private let inputFieldView = InputFieldStackView()
    private let cautionLabelWrapper = UIView()
    private let cautionLabel = UILabel()

    private let disposeBag = DisposeBag()
    private let viewModel: IVerifiedInputViewModel

    weak var delegate: IDynamicHeightCellDelegate?

    init(viewModel: IVerifiedInputViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        let wrapperView = UIView()
        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(Self.margin)
        }

        wrapperView.backgroundColor = .themeLawrence
        wrapperView.layer.cornerRadius = .cornerRadius2x
        wrapperView.layer.borderWidth = CGFloat.heightOnePixel
        wrapperView.layer.borderColor = UIColor.themeSteel20.cgColor

        wrapperView.addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        verticalStackView.axis = .vertical
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.layoutMargins = UIEdgeInsets(top: Self.stackInsideMargin, left: Self.stackInsideMargin, bottom: Self.stackInsideMargin, right: Self.stackInsideMargin)

        verticalStackView.addArrangedSubview(inputFieldView)
        verticalStackView.addArrangedSubview(cautionLabelWrapper)
        verticalStackView.spacing = Self.spacing

        inputFieldView.canEdit = viewModel.inputFieldCanEdit
        inputFieldView.decimalKeyboard = viewModel.decimalKeyboard
        inputFieldView.maximumNumberOfLines = viewModel.inputFieldMaximumNumberOfLines
        inputFieldView.append(items: viewModel.inputFieldButtonItems)
        inputFieldView.onChangeText = { [weak self] in
            self?.viewModel.inputFieldDidChange(text: $0)
        }
        inputFieldView.isValidText = { [weak self] in
            self?.viewModel.inputFieldIsValid(text: $0) ?? true
        }
        inputFieldView.onChangeHeight = { [weak self] _ in
            self?.delegate?.onChangeHeight()
        }

        if let placeholder = viewModel.inputFieldPlaceholder {
            inputFieldView.set(placeholder: placeholder)
        }
        inputFieldView.set(text: viewModel.inputFieldInitialValue)

        cautionLabelWrapper.addSubview(cautionLabel)
        cautionLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(Self.cautionMargin)
        }

        cautionLabel.font = Self.cautionFont
        cautionLabel.numberOfLines = 0
        cautionLabelWrapper.isHidden = true

        subscribe(disposeBag, viewModel.inputFieldCautionDriver) { [weak self] in self?.set(caution: $0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func set(caution: Caution?) {
        let setHidden = caution == nil
        let newText = caution?.text

        if setHidden {
            cautionLabel.text = nil
        }

        if cautionLabelWrapper.isHidden == setHidden && cautionLabel.text == newText {
            return
        }

        cautionLabelWrapper.isHidden = setHidden
        cautionLabel.text = caution?.text
        cautionLabel.textColor = caution?.type.color ?? cautionLabel.textColor

        delegate?.onChangeHeight()
    }

}

extension VerifiedInputCell {

    public var inputText: String {
        inputFieldView.inputText
    }

    override func becomeFirstResponder() -> Bool {
        inputFieldView.becomeFirstResponder()
    }

    public func height(containerWidth: CGFloat) -> CGFloat {
        let stackContentWidth = containerWidth - 2 * Self.margin - 2 * Self.stackInsideMargin

        var height = inputFieldView.height(containerWidth: stackContentWidth)

        if let error = cautionLabel.text {
            let errorHeight = error.height(forContainerWidth: stackContentWidth, font: Self.cautionFont)

            height += errorHeight + Self.spacing
        }

        return height + 2 * Self.stackInsideMargin
    }

}
