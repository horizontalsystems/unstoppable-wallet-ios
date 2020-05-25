import UIKit
import UIExtensions
import ThemeKit
import SnapKit

class FullTransactionHashHeaderView: UITableViewHeaderFooterView {
    private let descriptionView = ThemeButton()

    private var _onTap: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.trailing.equalTo(contentView.snp.trailingMargin)
            maker.height.equalTo(28)
        }

        descriptionView.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        descriptionView.apply(style: .secondaryDefault)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        _onTap?()
    }

    func bind(value: String?, onTap: (() -> ())?) {
        self._onTap = onTap

        descriptionView.setTitle(value, for: .normal)
    }

}
