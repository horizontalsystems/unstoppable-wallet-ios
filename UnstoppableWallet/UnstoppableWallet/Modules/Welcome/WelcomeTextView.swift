import UIKit
import SnapKit
import ThemeKit

class WelcomeTextView: UIView {

    init(title: String, description: String) {
        super.init(frame: .zero)

        let titleLabel = UILabel()

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
        }

        titleLabel.textAlignment = .center
        titleLabel.font = .title3
        titleLabel.textColor = .themeLeah
        titleLabel.text = title

        let descriptionLabel = UILabel()

        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin16)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .body
        descriptionLabel.textColor = .themeGray
        descriptionLabel.text = description
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
