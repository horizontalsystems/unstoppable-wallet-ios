import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class PagingDotsItemView: BaseActionItemView {

    var pageControl = UIPageControl()

    override var item: PagingDotsItem? { return _item as? PagingDotsItem }

    override func initView() {
        super.initView()
        pageControl.pageIndicatorTintColor = DepositTheme.pageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = DepositTheme.pageIndicatorSelectedTintColor
        addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        pageControl.numberOfPages = item?.pagesCount ?? 0
    }

    override func updateView() {
        super.updateView()
        pageControl.currentPage = item?.currentPage ?? 0
    }

}
