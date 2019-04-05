import UIKit
import GrouviExtensions
import SnapKit

class SectionSeparator: UITableViewHeaderFooterView {
    let topSeparatorView = UIView()
    let bottomSeparatorView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear

        topSeparatorView.backgroundColor = AppTheme.darkSeparatorColor
        contentView.addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
        bottomSeparatorView.backgroundColor = SettingsTheme.separatorColor
        addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(showTopSeparator: Bool = true, showBottomSeparator: Bool = true) {
        topSeparatorView.isHidden = !showTopSeparator
        bottomSeparatorView.isHidden = !showBottomSeparator
    }

}
