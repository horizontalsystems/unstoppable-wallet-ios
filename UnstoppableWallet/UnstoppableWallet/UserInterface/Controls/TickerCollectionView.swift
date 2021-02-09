import UIKit

protocol ITickerCollectionDataSource: AnyObject {
    var count: Int { get }
    func size(forItemAt index: Int) -> CGSize
    func cell(_ collectionView: UICollectionView, forItemAt index: Int) -> UICollectionViewCell
    func bind(_ cell: UICollectionViewCell, forItemAt index: Int)
}

class TickerCollectionView: UICollectionView {
    private let layout = UICollectionViewFlowLayout()
    private var tickerTimer: Timer?
    private var scrollingPoint: CGPoint = .zero
    private var duplicateCount: Int = 0

    public var cellMargin: CGFloat = .margin8
    public var scrollingInterval: TimeInterval = 0.02

    weak var tickerDataSource: ITickerCollectionDataSource?

    public init() {
        layout.scrollDirection = .horizontal

        super.init(frame: .zero, collectionViewLayout: layout)

        delegate = self
        dataSource = self

        allowsMultipleSelection = false
        showsHorizontalScrollIndicator = false
        scrollsToTop = false

        backgroundColor = .green
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private var duplicatedItemCount: Int {
        (tickerDataSource?.count ?? 0) * duplicateCount
    }

    private var itemsWidth: CGFloat {
        guard let tickerDataSource = tickerDataSource else {
            return .zero
        }

        var width: CGFloat = 0
        for index in 0..<tickerDataSource.count {
            width += tickerDataSource.size(forItemAt: index).width + cellMargin
        }

        return width
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let regularContentOffset = itemsWidth

        if (scrollView.contentOffset.x >= regularContentOffset * 2) {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x - regularContentOffset, y: scrollView.contentOffset.y)
        } else if (scrollView.contentOffset.x < regularContentOffset) {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x + regularContentOffset, y: scrollView.contentOffset.y)
        }

        scrollingPoint = scrollView.contentOffset
    }

    private func scrollForward() {
        contentOffset = scrollingPoint
        scrollingPoint = CGPoint(x: scrollingPoint.x + .heightOnePixel, y: scrollingPoint.y)
    }

    public func scrollToStart() {
        if duplicatedItemCount > 0 {
            contentOffset = CGPoint(x: itemsWidth - cellMargin, y: contentOffset.y)
        }
    }

    public func startScrolling() {
        scrollingPoint = contentOffset
        tickerTimer = Timer.scheduledTimer(withTimeInterval: scrollingInterval, repeats: true) { [weak self] _ in
            self?.scrollForward()
        }
    }

    public func stopScrolling() {
        tickerTimer?.invalidate()
        tickerTimer = nil
    }

}

extension TickerCollectionView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    open override func reloadData() {
        let itemsWidth = self.itemsWidth

        if itemsWidth != 0 && bounds.width != 0 {
            duplicateCount = Int(ceil(bounds.width / itemsWidth)) + 2
        } else {
            duplicateCount = 3
        }

        super.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        duplicatedItemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let tickerDataSource = tickerDataSource else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UICollectionViewCell.self), for: indexPath)
        }

        return tickerDataSource.cell(collectionView, forItemAt: indexPath.item % tickerDataSource.count)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let tickerDataSource = tickerDataSource else {
            return
        }
        tickerDataSource.bind(cell, forItemAt: indexPath.item % tickerDataSource.count)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let tickerDataSource = tickerDataSource else {
            return .zero
        }
        return tickerDataSource.size(forItemAt: indexPath.item % tickerDataSource.count)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        cellMargin
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        cellMargin
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        false
    }

}
