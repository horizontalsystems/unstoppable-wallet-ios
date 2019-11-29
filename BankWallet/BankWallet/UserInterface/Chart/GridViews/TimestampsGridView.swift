import UIKit

class TimestampsGridView: UIView {
    private let timelineHelper: ITimelineHelper

    private let timestampLinesLayer = TimestampLinesLayer()
    private let timestampTextLayer = TimestampTextLayer()

    weak var dataSource: IChartDataSource?

    private let configuration: ChartConfiguration
    var bottomPadding: CGFloat = .zero

    public init(timelineHelper: ITimelineHelper, configuration: ChartConfiguration) {
        self.timelineHelper = timelineHelper
        self.configuration = configuration

        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        layer.addSublayer(timestampLinesLayer)
        layer.addSublayer(timestampTextLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        timestampLinesLayer.frame = bounds

        let timestampTextLayerFrame = CGRect(x: 0, y: bounds.height - bottomPadding, width: bounds.width, height: bottomPadding)
        timestampTextLayer.frame = timestampTextLayerFrame

        refreshGrid()
    }

}

extension TimestampsGridView: IGridView {

    public func refreshGrid() {
        guard !bounds.isEmpty else {
            return
        }
        guard let dataSource = dataSource, !dataSource.chartData.isEmpty else {
            return
        }
        let chartFrame = dataSource.chartFrame

        let timestamps = timelineHelper.timestamps(frame: chartFrame, gridIntervalType: dataSource.gridIntervalType)

        // timestamp lines
        var insets = UIEdgeInsets.zero
        insets.bottom = bottomPadding
        timestampLinesLayer.refresh(configuration: configuration, insets: insets, chartFrame: dataSource.chartFrame, timestamps: timestamps)

        // timestamp texts
        timestampTextLayer.refresh(configuration: configuration, gridIntervalType: dataSource.gridIntervalType, insets: .zero, chartFrame: dataSource.chartFrame, timestamps: timestamps)
    }

    func update(bottomPadding: CGFloat) {
        self.bottomPadding = bottomPadding
    }

    func on(select: Bool) {
    }

}
