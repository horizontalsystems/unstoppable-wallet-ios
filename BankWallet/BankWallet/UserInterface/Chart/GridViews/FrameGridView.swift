import UIKit

class FrameGridView: UIView {
    private let frameHorizontalLinesLayer = FrameLinesLayer()
    weak var dataSource: IChartDataSource?

    private let configuration: ChartConfiguration
    var bottomPadding: CGFloat = .zero

    public init(configuration: ChartConfiguration) {
        self.configuration = configuration

        super.init(frame: .zero)

        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Can't init with aDecoder")
    }

    private func commonInit() {
        layer.addSublayer(frameHorizontalLinesLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        frameHorizontalLinesLayer.frame = bounds

        refreshGrid()
    }

}

extension FrameGridView: IGridView {

    func refreshGrid() {
        guard !bounds.isEmpty else {
            return
        }
        var insets = UIEdgeInsets.zero
        insets.bottom = bottomPadding

        frameHorizontalLinesLayer.refresh(configuration: configuration, insets: insets)
    }

    func update(bottomPadding: CGFloat) {
        self.bottomPadding = bottomPadding
    }

    func on(select: Bool) {
    }

}
