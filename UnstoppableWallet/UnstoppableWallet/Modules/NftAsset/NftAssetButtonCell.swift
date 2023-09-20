import ComponentKit
import UIKit

class NftAssetButtonCell: UITableViewCell {
    private let saveButton = PrimaryButton()
    private let shareButton = PrimaryButton()

    private let stackView = UIStackView()

    private var onTapShare: (() -> Void)?
    private var onTapSave: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        stackView.addArrangedSubview(shareButton)
        stackView.addArrangedSubview(saveButton)

        stackView.spacing = .margin8
        stackView.alignment = .fill
        stackView.distribution = .fillEqually

        shareButton.set(style: .yellow)
        shareButton.addTarget(self, action: #selector(onTapShareButton), for: .touchUpInside)
        shareButton.setTitle("button.share".localized, for: .normal)

        saveButton.set(style: .gray)
        saveButton.addTarget(self, action: #selector(onTapSaveButton), for: .touchUpInside)
        saveButton.setTitle("button.save".localized, for: .normal)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSaveButton() {
        onTapSave?()
    }

    @objc private func onTapShareButton() {
        onTapShare?()
    }

    func bind(onTapShare: @escaping () -> Void, onTapSave: @escaping () -> Void) {
        self.onTapShare = onTapShare
        self.onTapSave = onTapSave
    }
}
