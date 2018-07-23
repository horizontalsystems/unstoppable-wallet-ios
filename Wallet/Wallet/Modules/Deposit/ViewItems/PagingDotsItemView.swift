import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class PagingDotsItemView: BaseActionItemView {

    var pageControl = UIPageControl()

    override var item: PagingDotsItem? { return _item as? PagingDotsItem }

    override func initView() {
        super.initView()
        pageControl.isUserInteractionEnabled = false
        pageControl.pageIndicatorTintColor = DepositTheme.pageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = DepositTheme.pageIndicatorSelectedTintColor
        addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(DepositTheme.pagingDotsTopMargin)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(DepositTheme.pagingDotsHeight)
        }
        pageControl.numberOfPages = item?.pagesCount ?? 0

        item?.updateView = { [weak self] in
            self?.updateView()
        }
    }

    override func updateView() {
        super.updateView()
        pageControl.currentPage = item?.currentPage ?? 0
    }

}
