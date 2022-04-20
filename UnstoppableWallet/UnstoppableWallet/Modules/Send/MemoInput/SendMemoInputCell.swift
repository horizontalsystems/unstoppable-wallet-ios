import UIKit
import ThemeKit
import SnapKit
import RxSwift

class SendMemoInputCell: UITableViewCell {
    private let disposeBag = DisposeBag()
    private let viewModel: SendMemoInputViewModel

    private let wrapperView = UIView()
    private let anInputView: InputView
    private let topInset: CGFloat

    private var hiddenState: Bool = false
    var onChangeHeight: (() -> ())?

    init(viewModel: SendMemoInputViewModel, topInset: CGFloat = 0) {    // topInset used for make header padding, which may be dynamically collapse
        self.viewModel = viewModel
        self.topInset = topInset

        anInputView = InputView(singleLine: true)
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        wrapperView.clipsToBounds = true

        wrapperView.addSubview(anInputView)
        anInputView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(topInset)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(anInputView.height(containerWidth: 0))
        }

        anInputView.inputPlaceholder = "send.confirmation.memo_placeholder".localized
        anInputView.font = UIFont.body.with(traits: .traitItalic)


        anInputView.onChangeText = { [weak self] in
            self?.viewModel.change(text: $0)
        }

        anInputView.isValidText = { [weak self] in
            self?.viewModel.isValid(text: $0) ?? false
        }

        subscribe(disposeBag, viewModel.isHiddenDriver) { [weak self] in self?.sync(hidden: $0) }
        sync(hidden: viewModel.isHidden)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(hidden: Bool) {
        hiddenState = hidden
        onChangeHeight?()
    }

}

extension SendMemoInputCell {

    func height(containerWidth: CGFloat) -> CGFloat {
        let height = anInputView.height(containerWidth: containerWidth) + topInset
        return hiddenState ? 0 : height
    }

}
