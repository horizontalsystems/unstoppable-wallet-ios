import Foundation
import UIKit
import SnapKit

class ApprovingView: UIView {
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let titleLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)

        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        activityIndicator.hidesWhenStopped = false

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(activityIndicator.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.centerY.equalToSuperview()
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeGray50
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension ApprovingView {

    public func startAnimating(_ start: Bool) {
        if start {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

}
