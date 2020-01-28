import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class PagingDotsItemView: BaseActionItemView {
    private let pageControl = UIPageControl()

    override var item: PagingDotsItem? {
        _item as? PagingDotsItem
    }

    override func initView() {
        super.initView()

        addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(23)
            maker.height.equalTo(7)
        }

        pageControl.isUserInteractionEnabled = false
        pageControl.pageIndicatorTintColor = .themeSteel20
        pageControl.currentPageIndicatorTintColor = .themeRemus
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
