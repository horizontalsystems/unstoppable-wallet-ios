import SnapKit
import ActionSheet

class BaseTwinItemView: BaseActionItemView {

    var firstContainerView = UIView()
    var secondContainerView = UIView()

    override var item: BaseTwinItem? { return _item as? BaseTwinItem }

    var firstItemView: BaseActionItemView?
    var secondItemView: BaseActionItemView?

    var firstItemInstance: BaseActionItemView {
        fatalError("Should be overriden")
    }

    var secondItemInstance: BaseActionItemView {
        fatalError("Should be overriden")
    }

    func initItems(first firstItem: BaseActionItem, second secondItem: BaseActionItem) {
        addSubview(firstContainerView)
        addSubview(secondContainerView)

        firstItemView = firstItemInstance
        firstItemView?._item = firstItem
        if let leftItemView = firstItemView {
            firstContainerView.addSubview(leftItemView)
            leftItemView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }
        firstItemView?.initView()

        secondItemView = secondItemInstance
        secondItemView?._item = secondItem
        if let rightItemView = secondItemView {
            secondContainerView.addSubview(rightItemView)
            rightItemView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }
        }
        secondItemView?.initView()
    }

    override func initView() {
        super.initView()

        if let item = item {
            initItems(first: item.firstItem, second: item.secondItem)

            item.updateItems = { [weak self] right in
                self?.updateItemViews(forRightSide: right)
            }

            updateView()
            layoutIfNeeded()
        }
    }

    func updateItemViews(forRightSide right: Bool = true) {
        let view: BaseActionItemView? = right ? secondItemView : firstItemView
        view?.updateView()
    }

    override func updateView() {
        super.updateView()

        let showSearch = !(item?.showFirstItem ?? true)
        showFirstItemView(!showSearch)
    }

    func showFirstItemView(_ show: Bool) {
        let style = item?.changeStyle ?? .fromRight
        if let height = show ? item?.firstItem.height : item?.secondItem.height {
            _item.height = height
        }

        if style == .alpha {
            firstContainerView.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            secondContainerView.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            let view: UIView = show ? firstContainerView : secondContainerView
            ActionSheetAnimation.animation({ [weak self] in
                self?.firstContainerView.alpha = show ? 1 : 0
                self?.secondContainerView.alpha = show ? 0 : 1
            }, completion: { [weak self] b in
                self?.bringSubviewToFront(view)
            })
        } else {
            if show {
                firstContainerView.snp.remakeConstraints { maker in
                    maker.edges.equalToSuperview()
                }
                secondContainerView.snp.remakeConstraints { maker in
                    maker.top.bottom.equalToSuperview()
                    if style == .fromLeft {
                        maker.leading.equalTo(firstContainerView.snp.trailing)
                    } else {
                        maker.trailing.equalTo(firstContainerView.snp.leading)
                    }
                    maker.width.equalTo(firstContainerView.snp.width)
                }
            } else {
                secondContainerView.snp.remakeConstraints { maker in
                    maker.edges.equalToSuperview()
                }
                firstContainerView.snp.remakeConstraints { maker in
                    maker.top.bottom.equalToSuperview()
                    if style == .fromLeft {
                        maker.trailing.equalTo(secondContainerView.snp.leading)
                    } else {
                        maker.leading.equalTo(secondContainerView.snp.trailing)
                    }
                    maker.width.equalTo(secondContainerView.snp.width)
                }
            }
        }
    }

}
