import UIKit
import Chart
import SnapKit
import HUD

class PostHeaderView: UIView {
    private static let spinnerLineWidth: CGFloat = 3
    private static let spinnerRadius: CGFloat = 11

    private let syncSpinner = HUDProgressView(
            strokeLineWidth: PostHeaderView.spinnerLineWidth,
            radius: PostHeaderView.spinnerRadius,
            strokeColor: .themeOz
    )
    private let failedView = UIImageView(image: UIImage(named: "Attention Icon")?.withRenderingMode(.alwaysTemplate))
    private let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence

        addSubview(titleLabel)
        addSubview(syncSpinner)
        addSubview(failedView)

        syncSpinner.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(2 * PostHeaderView.spinnerRadius + PostHeaderView.spinnerLineWidth)
        }

        failedView.snp.makeConstraints { maker in
            maker.edges.equalTo(syncSpinner)
        }
        failedView.tintColor = .themeLucian
        failedView.isHidden = true
        failedView.contentMode = .center

        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.trailing.equalTo(syncSpinner.snp.leading).offset(-CGFloat.margin4x)
        }
        titleLabel.font = .headline2
        titleLabel.textColor = .themeLeah
        titleLabel.text = "chart.news.title".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(showSpinner: Bool, showFailed: Bool = false) {
        if showSpinner {
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
            syncSpinner.stopAnimating()
        }
        failedView.isHidden = !showFailed
    }

    func bind(showFailed: Bool) {
        bind(showSpinner: false, showFailed: true)
    }

}

extension PostHeaderView {

    static var height: CGFloat {
        52
    }

}
