import UIKit
import SnapKit
import ThemeKit

class IntroPageView: UIView {

    init(title: String?, description: String, bottomInset: CGFloat) {
        super.init(frame: .zero)

        let wrapperView = UIView()

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(self.safeAreaLayoutGuide)
            maker.bottom.equalTo(self.safeAreaLayoutGuide).inset(bottomInset)
        }

        let textWrapperView = UIView()

        wrapperView.addSubview(textWrapperView)
        textWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalToSuperview().multipliedBy(1.0 / 3.0)
        }

        let titleLabel = UILabel()

        textWrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.equalToSuperview()
            if title == nil {
                maker.height.equalTo(0)
            }
        }

        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = .title3
        titleLabel.textColor = .themeLight
        titleLabel.text = title

        let descriptionLabel = UILabel()

        textWrapperView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.equalTo(titleLabel.snp.bottom).offset(title == nil ? 0 : CGFloat.margin16)
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
