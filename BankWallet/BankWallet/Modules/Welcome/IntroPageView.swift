import UIKit
import SnapKit
import ThemeKit

class IntroPageView: UIView {

    init(title: String, description: String) {
        super.init(frame: .zero)

        let wrapperView = UIView()

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalToSuperview().dividedBy(2)
        }

        let titleLabel = UILabel()

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin6x)
        }

        titleLabel.textAlignment = .center
        titleLabel.font = .title3
        titleLabel.textColor = .themeLight
        titleLabel.text = title

        let descriptionLabel = UILabel()

        wrapperView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin4x)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .body
        descriptionLabel.textColor = .themeLightGray
        descriptionLabel.text = description
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
