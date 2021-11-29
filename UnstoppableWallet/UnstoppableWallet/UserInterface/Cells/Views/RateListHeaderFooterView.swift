import UIKit
import ThemeKit
import ComponentKit

class RateListHeaderFooterView: UITableViewHeaderFooterView {
    static let height: CGFloat = 66

    private let dateLabel = UILabel()
    private let separatorView = UIView()
    private let titleLabel = UILabel()
    private let sortButton = ThemeButton()

    private var onTapSort: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin1x)
        }

        dateLabel.font = .caption
        dateLabel.textColor = .themeGray

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeOz

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(titleLabel.snp.top).offset(-CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing)
            maker.top.equalTo(separatorView.snp.bottom)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.width.equalTo(CGFloat.margin4x + 24 + CGFloat.margin4x)
        }

        sortButton.setImage(UIImage(named: "sort_6_24")?.withTintColor(.themeJacob), for: .normal)
        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSortButton() {
        onTapSort?()
    }

    func bind(title: String, lastUpdated: Date?, sortButtonState: SortButtonState) {
        titleLabel.text = title
        dateLabel.text = lastUpdated.map { DateHelper.instance.formatRateListTitle(from: $0) }

        switch sortButtonState {
        case .hidden:
            sortButton.isHidden = true
        case .disabled:
            sortButton.isHidden = false
            sortButton.isEnabled = false
        case .enabled(let onTap):
            sortButton.isHidden = false
            sortButton.isEnabled = true
            onTapSort = onTap
        }
    }

}

extension RateListHeaderFooterView {

    enum SortButtonState {
        case hidden
        case disabled
        case enabled(onTap: () -> ())
    }

}
