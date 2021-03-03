import UIKit
import ThemeKit
import SnapKit

class MultiTextMetricsView: UIView {
    static let titleHeight: CGFloat = MultiTextMetricsView.titleFont.lineHeight

    private static let titleFont: UIFont = .caption

    private let titleLabel = UILabel()
    private let metricsStackView = UIStackView()
    private var metricViews = [MetricsView]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().inset(CGFloat.margin16)
        }

        titleLabel.font = MultiTextMetricsView.titleFont
        titleLabel.textColor = .themeGray

        let separator = UIView()
        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin4)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separator.backgroundColor = .themeSteel10

        addSubview(metricsStackView)
        metricsStackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalTo(separator.snp.bottom).offset(CGFloat.margin8)
        }

        metricsStackView.axis = .vertical
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    public var metricsViewItems: [MetricsViewItem] = [] {
        didSet {
            fillStackView()
        }
    }

    private func fillStackView() {
        guard metricViews.count != metricsViewItems.count else {
            metricViews.enumerated().forEach { index, view in
                bind(view: view, viewItem: metricsViewItems[index])
            }

            return
        }


        metricViews.forEach { view in metricsStackView.removeArrangedSubview(view) }
        metricViews = []

        metricsViewItems.enumerated().forEach { index, item in
            let view = MetricsView()
            bind(view: view, viewItem: item)
            metricsStackView.addArrangedSubview(view)
            metricViews.append(view)
        }
    }

    private func bind(view: MetricsView, viewItem: MetricsViewItem) {
        view.value = viewItem.value
        view.valueChange = viewItem.valueChange
        view.valueChangeColor = viewItem.valueChangeColor
    }

    static func viewHeight(viewItems: [MultiTextMetricsView.MetricsViewItem]) -> CGFloat {
        CGFloat.margin16 + MultiTextMetricsView.titleHeight + CGFloat.margin4 + CGFloat.heightOnePixel + CGFloat.margin8 + CGFloat(viewItems.count) * MetricsView.viewHeight + CGFloat.margin8
    }

}

extension MultiTextMetricsView {

    struct MetricsViewItem {
        init(value: String?) {
            self.value = value
            valueChange = nil
            valueChangeColor = nil
        }

        init(value: String?, valueChange: String?, valueChangeColor: UIColor?) {
            self.value = value
            self.valueChange = valueChange
            self.valueChangeColor = valueChangeColor
        }

        let value: String?
        let valueChange: String?
        let valueChangeColor: UIColor?
    }

    class MetricsView: UIView {
        static let viewHeight: CGFloat = valueFont.lineHeight + bottomInset

        private static let bottomInset: CGFloat = CGFloat.margin8
        private static let valueFont: UIFont = .subhead1

        private let valueLabel = UILabel()
        private let valueChangeLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(valueLabel)
            valueLabel.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().inset(CGFloat.margin16)
                maker.top.equalToSuperview()
                maker.bottom.equalToSuperview().inset(MetricsView.bottomInset)
            }

            valueLabel.setContentHuggingPriority(.required, for: .horizontal)
            valueLabel.font = MetricsView.valueFont
            valueLabel.textColor = .themeBran

            addSubview(valueChangeLabel)
            valueChangeLabel.snp.makeConstraints { maker in
                maker.leading.equalTo(valueLabel.snp.trailing).offset(CGFloat.margin4)
                maker.centerY.equalTo(valueLabel)
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            }

            valueChangeLabel.font = .caption
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public var value: String? {
            get { valueLabel.text }
            set { valueLabel.text = newValue }
        }

        public var valueChange: String? {
            get { valueChangeLabel.text }
            set { valueChangeLabel.text = newValue }
        }

        public var valueChangeColor: UIColor? {
            get { valueChangeLabel.textColor }
            set { valueChangeLabel.textColor = newValue }
        }

    }

}
