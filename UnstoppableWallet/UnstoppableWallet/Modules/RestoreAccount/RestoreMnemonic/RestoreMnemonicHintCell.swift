import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class RestoreMnemonicHintCell: UICollectionViewCell {
    private let button = SecondaryButton()

    private var onTap: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.centerY.equalToSuperview()
        }

        button.set(style: .default)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

    func bind(word: String, onTap: @escaping () -> ()) {
        button.setTitle(word, for: .normal)

        self.onTap = onTap
    }

}

extension RestoreMnemonicHintCell {

    static func size(word: String) -> CGSize {
        CGSize(width: SecondaryButton.width(title: word), height: .heightSingleLineCell)
    }

}
