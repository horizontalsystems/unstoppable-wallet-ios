import UIKit

class LimitsGridView: UIView {
    private let limitLinesLayer = LimitLinesLayer()
    private let limitTextLayer = LimitTextLayer()

    weak var dataSource: IChartDataSource?

    private let configuration: ChartConfiguration
    private let pointConverter: IPointConverter

    var bottomPadding: CGFloat = .zero

    public init(configuration: ChartConfiguration, pointConverter: IPointConverter) {
        self.configuration = configuration
        self.pointConverter = pointConverter

        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        layer.addSublayer(limitLinesLayer)
        layer.addSublayer(limitTextLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        limitLinesLayer.frame = bounds
        limitTextLayer.frame = bounds

        refreshGrid()
    }

}

extension LimitsGridView: IGridView {

    func refreshGrid() {
        guard !bounds.isEmpty else {
            return
        }
        guard let dataSource = dataSource, !dataSource.chartData.isEmpty else {
            return
        }
        let chartFrame = dataSource.chartFrame

        var insets = UIEdgeInsets.zero
        insets.bottom = bottomPadding

        limitLinesLayer.refresh(configuration: configuration, pointConverter: pointConverter, insets: insets, chartFrame: chartFrame)
        limitTextLayer.refresh(configuration: configuration, pointConverter: pointConverter, insets: insets, chartFrame: chartFrame)
    }

    func update(bottomPadding: CGFloat) {
        self.bottomPadding = bottomPadding
    }

    func on(select: Bool) {
        limitTextLayer.isHidden = select
    }

}
