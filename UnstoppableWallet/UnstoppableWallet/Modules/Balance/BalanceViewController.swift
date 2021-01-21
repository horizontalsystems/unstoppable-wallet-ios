import UIKit
import SnapKit
import DeepDiff
import ActionSheet
import ThemeKit
import HUD

class BalanceViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2

    private let numberOfSections = 2
    private let balanceSection = 0
    private let editSection = 1

    private let horizontalInset: CGFloat = .margin4x
    private let lineSpacing: CGFloat = .margin2x

    private let delegate: IBalanceViewDelegate

    private let layout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView
    private let refreshControl = UIRefreshControl()

    private var headerViewItem: BalanceHeaderViewItem?
    private var viewItems = [BalanceViewItem]()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.balance_view", qos: .userInitiated)

    init(viewDelegate: IBalanceViewDelegate) {
        delegate = viewDelegate

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init()

        tabBarItem = UITabBarItem(title: "balance.tab_bar_item".localized, image: UIImage(named: "filled_wallet_24"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "balance.title".localized

        refreshControl.tintColor = .themeLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        layout.sectionHeadersPinToVisibleBounds = true

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear

        collectionView.register(BalanceCell.self, forCellWithReuseIdentifier: String(describing: BalanceCell.self))
        collectionView.register(BalanceEditCell.self, forCellWithReuseIdentifier: String(describing: BalanceEditCell.self))
        collectionView.register(BalanceHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: BalanceHeaderView.self))

        delegate.onLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView.refreshControl = refreshControl

        delegate.onAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        delegate.onDisappear()
    }

    @objc func onRefresh() {
        delegate.onTriggerRefresh()
    }

    @objc private func onTapHideBalance() {
        delegate.onTapHideBalance()
    }

    @objc private func onTapShowBalance() {
        delegate.onTapShowBalance()
    }

    private func handle(newHeaderViewItem: BalanceHeaderViewItem?, newViewItems: [BalanceViewItem]) {
        let changes = diff(old: viewItems, new: newViewItems)

        if changes.contains(where: {
            if case .insert = $0 { return true }
            if case .delete = $0 { return true }
            return false
        }) {
            DispatchQueue.main.sync {
                headerViewItem = newHeaderViewItem
                viewItems = newViewItems
                collectionView.reloadData()
                syncShowBalanceButton()
            }
            return
        }

        let headerVisible = headerViewItem != nil
        let newHeaderVisible = newHeaderViewItem != nil

        var heightChange = headerVisible != newHeaderVisible

        if !heightChange {
            for (index, oldViewItem) in viewItems.enumerated() {
                let newViewItem = newViewItems[index]

                let oldHeight = BalanceCell.height(viewItem: oldViewItem)
                let newHeight = BalanceCell.height(viewItem: newViewItem)

                if oldHeight != newHeight {
                    heightChange = true
                    break
                }
            }
        }

        var updateIndexes = Set<Int>()

        for change in changes {
            switch change {
            case .move(let move):
                updateIndexes.insert(move.fromIndex)
                updateIndexes.insert(move.toIndex)
            case .replace(let replace):
                updateIndexes.insert(replace.index)
            default: ()
            }
        }

        DispatchQueue.main.sync {
            headerViewItem = newHeaderViewItem
            viewItems = newViewItems
            syncShowBalanceButton()

            if let view = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? BalanceHeaderView {
                bind(view: view)
            }

            updateIndexes.forEach {
                if let cell = collectionView.cellForItem(at: IndexPath(row: $0, section: balanceSection)) as? BalanceCell {
                    bind(cell: cell, viewItem: viewItems[$0], animated: heightChange)
                }
            }

            if heightChange {
                UIView.animate(withDuration: animationDuration) {
                    self.collectionView.performBatchUpdates(nil)
                }
            }
        }
    }

    private func bind(cell: BalanceCell, viewItem: BalanceViewItem, animated: Bool = false) {
        cell.bind(
                viewItem: viewItem,
                animated: animated,
                duration: animationDuration,
                onReceive: { [weak self] in
                    self?.delegate.onTapReceive(viewItem: viewItem)
                },
                onPay: { [weak self] in
                    self?.delegate.onTapPay(viewItem: viewItem)
                },
                onSwap: { [weak self] in
                    self?.delegate.onTapSwap(viewItem: viewItem)
                },
                onChart: { [weak self] in
                    self?.delegate.onTapChart(viewItem: viewItem)
                },
                onTapError: { [weak self] in
                    self?.delegate.onTapFailedIcon(viewItem: viewItem)
                }
        )
    }

    private func bind(view: BalanceHeaderView) {
        if let viewItem = headerViewItem {
            view.bind(viewItem: viewItem)
            view.layoutIfNeeded()

            view.onTapSortType = { [weak self] in
                self?.delegate.onTapSortType()
            }
        }
    }

    private func syncShowBalanceButton() {
        if headerViewItem == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "eye_2_off_24"), style: .plain, target: self, action: #selector(onTapShowBalance))
            navigationItem.rightBarButtonItem?.tintColor = .themeJacob
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "eye_2_24"), style: .plain, target: self, action: #selector(onTapHideBalance))
            navigationItem.rightBarButtonItem?.tintColor = .themeGray
        }
    }

}

extension BalanceViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        numberOfSections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == balanceSection {
            return viewItems.count
        } else if section == editSection {
            return 1
        }

        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == balanceSection {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BalanceCell.self), for: indexPath)
        } else if indexPath.section == editSection {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: BalanceEditCell.self), for: indexPath)
        }

        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: BalanceHeaderView.self), for: indexPath)
    }

}

extension BalanceViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BalanceCell {
            bind(cell: cell, viewItem: viewItems[indexPath.item])
        } else if let cell = cell as? BalanceEditCell {
            cell.onTap = { [weak self] in
                self?.delegate.onTapAddCoin()
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let view = view as? BalanceHeaderView {
            bind(view: view)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == balanceSection {
            delegate.onTap(viewItem: viewItems[indexPath.item])
        }
    }

}

extension BalanceViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == balanceSection {
            return CGSize(width: collectionView.width - horizontalInset * 2, height: BalanceCell.height(viewItem: viewItems[indexPath.item]))
        } else if indexPath.section == editSection {
            return CGSize(width: collectionView.width, height: BalanceEditCell.height)
        }

        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        lineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == balanceSection {
            return UIEdgeInsets(top: lineSpacing, left: horizontalInset, bottom: lineSpacing, right: horizontalInset)
        }

        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == balanceSection {
            return CGSize(width: collectionView.width, height: headerViewItem == nil ? CGFloat.ulpOfOne : BalanceHeaderView.height)
        }

        return .zero
    }

}

extension BalanceViewController: IBalanceView {

    func set(headerViewItem: BalanceHeaderViewItem?, viewItems: [BalanceViewItem]) {
        queue.async {
            self.handle(newHeaderViewItem: headerViewItem, newViewItems: viewItems)
        }
    }

    func hideRefresh() {
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
    }

    func show(error: Error) {
        DispatchQueue.main.async {
            HudHelper.instance.showError(title: error.smartDescription)
        }
    }

    func showLostAccounts() {
        let controller = UIAlertController(title: "lost_accounts.warning_title".localized, message: "lost_accounts.warning_message".localized, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "button.ok".localized, style: .default))
        controller.show()
    }

}
