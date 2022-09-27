import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class BackupMnemonicWordCell: UICollectionViewCell {
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

    func bind(viewItem: BackupVerifyWordsViewModel.WordViewItem, onTap: @escaping () -> ()) {
        button.setTitle(viewItem.text, for: .normal)
        button.isEnabled = viewItem.enabled

        self.onTap = onTap
    }

}

extension BackupMnemonicWordCell {

    static func size(word: String) -> CGSize {
        CGSize(width: SecondaryButton.width(title: word), height: SecondaryButton.height)
    }

}
