import UIKit

class ChartIntervalAndSelectedRateCell: UITableViewCell {
    enum DisplayMode {
        case interval
        case selectedRate
    }

    private let intervalSelectView = FilterHeaderView(buttonStyle: .secondaryTransparent)
    private let selectedRateView = ChartPointInfoView()

    public var onSelectInterval: ((Int) -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(selectedRateView)
        selectedRateView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }
        selectedRateView.isHidden = true

        contentView.addSubview(intervalSelectView)
        intervalSelectView.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(selectedRateView)
            maker.leading.trailing.equalToSuperview()
        }

        intervalSelectView.onSelect = { [weak self] index in
            self?.onSelectInterval?(index)
        }

        let separator = UIView()
        contentView.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separator.backgroundColor = .themeSteel10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func bind(displayMode: DisplayMode) {
        switch displayMode {
        case .interval:
            intervalSelectView.isHidden = false
            selectedRateView.isHidden = true
        case .selectedRate:
            intervalSelectView.isHidden = true
            selectedRateView.isHidden = false
        }
    }

    public func bind(filters: [FilterHeaderView.ViewItem]) {
        intervalSelectView.reload(filters: filters)
    }

    public func select(index: Int) {
        intervalSelectView.select(index: index)
    }

    public func bind(selectedPointViewItem: SelectedPointViewItem) {
        selectedRateView.bind(viewItem: selectedPointViewItem)
    }

    func set(backgroundColor: UIColor?) {
        intervalSelectView.backgroundView?.backgroundColor = backgroundColor
    }

}
