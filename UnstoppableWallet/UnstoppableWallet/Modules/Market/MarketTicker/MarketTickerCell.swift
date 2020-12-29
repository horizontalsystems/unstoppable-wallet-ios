import UIKit
import SnapKit
import ThemeKit
import RxSwift

class MarketTickerCell: UITableViewCell {
    static let cellHeight: CGFloat = 38

    private let disposeBag = DisposeBag()
    private let tickerCollectionView = TickerCollectionView()
    private let tickerDataSource = MarketTickerDataSource()

    private let viewModel: MarketTickerViewModel

    init(viewModel: MarketTickerViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(tickerCollectionView)
        tickerCollectionView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }
        layoutIfNeeded()

        tickerCollectionView.tickerDataSource = tickerDataSource
        tickerCollectionView.registerCell(forClass: MarketTickerCollectionCell.self)

        tickerCollectionView.backgroundColor = .themeAndy
        tickerCollectionView.clipsToBounds = true
        tickerCollectionView.layer.cornerRadius = Self.cellHeight / 2

        subscribe(disposeBag, viewModel.tickerDataDriver) { [weak self] in self?.sync(tickerData: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(tickerData: [MarketTickerViewModel.ViewItem]) {
        tickerDataSource.set(items: tickerData)
        tickerCollectionView.reloadData()

        //todo: stop scrolling on willDisappearView
        tickerCollectionView.scrollToStart()
        tickerCollectionView.startScrolling()
    }

}

extension MarketTickerCell {

    public func refresh() {
        viewModel.refresh()
    }

}
