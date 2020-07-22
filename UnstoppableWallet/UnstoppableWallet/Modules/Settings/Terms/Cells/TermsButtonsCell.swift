import UIKit
import SnapKit
import ThemeKit

class TermsButtonsCell: UITableViewCell {
    static let height: CGFloat = 100

    private var onTapGithub: (() -> ())?
    private var onTapSite: (() -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        let githubButton = ThemeButton()

        contentView.addSubview(githubButton)
        githubButton.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(CGFloat.margin6x)
        }

        githubButton.apply(style: .secondaryDefault)
        githubButton.setTitle("GitHub", for: .normal)
        githubButton.addTarget(self, action: #selector(_onTapGithub), for: .touchUpInside)

        let siteButton = ThemeButton()

        contentView.addSubview(siteButton)
        siteButton.snp.makeConstraints { maker in
            maker.leading.equalTo(githubButton.snp.trailing).offset(CGFloat.margin2x)
            maker.top.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.width.equalTo(githubButton)
        }

        siteButton.apply(style: .secondaryDefault)
        siteButton.setTitle("terms.site".localized, for: .normal)
        siteButton.addTarget(self, action: #selector(_onTapSite), for: .touchUpInside)

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(githubButton.snp.bottom).offset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc private func _onTapGithub() {
        onTapGithub?()
    }

    @objc private func _onTapSite() {
        onTapSite?()
    }

    func bind(onTapGithub: @escaping () -> (), onTapSite: @escaping () -> ()) {
        self.onTapGithub = onTapGithub
        self.onTapSite = onTapSite
    }

}
