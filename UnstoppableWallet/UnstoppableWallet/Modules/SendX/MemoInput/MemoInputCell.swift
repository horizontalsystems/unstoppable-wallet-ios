import UIKit
import ThemeKit
import SnapKit

class MemoInputCell: UITableViewCell {
    private let viewModel: MemoInputViewModel

    private let anInputView: InputView

    init(viewModel: MemoInputViewModel) {
        self.viewModel = viewModel

        anInputView = InputView(singleLine: true)
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        anInputView.inputPlaceholder = "send.confirmation.memo_placeholder".localized
        anInputView.font = UIFont.body.with(traits: .traitItalic)

        contentView.addSubview(anInputView)
        anInputView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        anInputView.onChangeText = { [weak self] in
            self?.viewModel.change(text: $0)
        }

        anInputView.isValidText = { [weak self] in
            self?.viewModel.isValid(text: $0) ?? false
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MemoInputCell {

    func height(containerWidth: CGFloat) -> CGFloat {
        anInputView.height(containerWidth: containerWidth)
    }

}
