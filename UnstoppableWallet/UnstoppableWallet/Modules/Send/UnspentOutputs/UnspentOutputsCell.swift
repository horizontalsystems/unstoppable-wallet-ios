import Combine
import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class UnspentOutputsCell: BaseSelectableThemeCell {
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: UnspentOutputsViewModel

    private let title = UILabel()
    private let text = UILabel()
    private let editImageView = UIImageView()

    init(viewModel: UnspentOutputsViewModel, isFirst: Bool = true, isLast: Bool = true) { // topInset used for make header padding, which may be dynamically collapse
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        wrapperView.addSubview(title)
        title.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(CGFloat.margin16)
        }

        title.font = .subhead2
        title.textColor = .themeGray
        title.text = "send.unspent_outputs".localized

        title.setContentHuggingPriority(.required, for: .horizontal)

        wrapperView.addSubview(text)
        text.snp.makeConstraints { maker in
            maker.leading.equalTo(title.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalToSuperview().inset(CGFloat.margin16)
        }

        text.font = .subhead1
        text.textColor = .themeGray
        text.textAlignment = .right

        wrapperView.addSubview(editImageView)
        editImageView.snp.makeConstraints { maker in
            maker.leading.equalTo(text.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalToSuperview().inset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        editImageView.image = UIImage(named: "edit_20")?.withRenderingMode(.alwaysTemplate)
        editImageView.setContentHuggingPriority(.required, for: .horizontal)
        editImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        viewModel.$item
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(item: $0) }
            .store(in: &cancellables)

        viewModel.$isCustom
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(isCustom: $0) }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(item: UnspentOutputsViewModel.UnspentOutputsItem) {
        text.text = [item.selected.description, item.all.description].joined(separator: " / ")
    }

    private func sync(isCustom: Bool) {
        editImageView.tintColor = isCustom ? .themeJacob : .themeGray
    }
}
