import UIKit

class GridView: UIView {
    private let timeLineHelper = TimelineHelper()
    private let valueLinesLayer = ValueLinesLayer()
    private let timestampLinesLayer = TimestampLinesLayer()
    private let valueTextLayer = ValueTextLayer()
    private let timestampTextLayer = TimestampTextLayer()
    weak var dataSource: IChartDataSource?

    private let configuration: ChartConfiguration
    var scaleOffsetSize: CGSize = .zero

    public init(configuration: ChartConfiguration) {
        self.configuration = configuration

        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        layer.addSublayer(valueLinesLayer)
        layer.addSublayer(timestampLinesLayer)
        layer.addSublayer(valueTextLayer)
        layer.addSublayer(timestampTextLayer)
    }

    public func refreshGrid() {
        guard !bounds.isEmpty else {
            return
        }
        guard let dataSource = dataSource, !dataSource.chartData.isEmpty else {
            return
        }
        let chartFrame = dataSource.chartFrame

        // value lines
        var insets = UIEdgeInsets.zero
        insets.bottom = scaleOffsetSize.height
        valueLinesLayer.refresh(configuration: configuration, insets: insets)

        // value texts
        insets = UIEdgeInsets.zero
        insets.bottom = scaleOffsetSize.height
        valueTextLayer.refresh(configuration: configuration, insets: insets, chartFrame: chartFrame)

        let timestamps = timeLineHelper.timestamps(frame: chartFrame, type: dataSource.chartType)

        // timestamp lines
        insets = UIEdgeInsets.zero
        insets.right = scaleOffsetSize.width
        insets.bottom = scaleOffsetSize.height
        timestampLinesLayer.refresh(configuration: configuration, insets: insets, chartFrame: dataSource.chartFrame, timestamps: timestamps)

        // timestamp texts
        insets = UIEdgeInsets.zero
        insets.right = scaleOffsetSize.width
        timestampTextLayer.refresh(configuration: configuration, chartType: dataSource.chartType, insets: insets, chartFrame: dataSource.chartFrame, timestamps: timestamps)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        valueLinesLayer.frame = bounds
        timestampLinesLayer.frame = bounds

        let valueTextLayerFrame = CGRect(x: bounds.width - scaleOffsetSize.width, y: 0, width: scaleOffsetSize.width, height: bounds.height)
        valueTextLayer.frame = valueTextLayerFrame

        let timestampTextLayerFrame = CGRect(x: 0, y: bounds.height - scaleOffsetSize.height, width: bounds.width, height: scaleOffsetSize.height)
        timestampTextLayer.frame = timestampTextLayerFrame

        refreshGrid()
    }

}
