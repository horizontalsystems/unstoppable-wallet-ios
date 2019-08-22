import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class DepositCollectionItemView: BaseActionItemView {

    var collectionView: UICollectionView?

    override var item: DepositCollectionItem? { return _item as? DepositCollectionItem }

    override func initView() {
        super.initView()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.registerCell(forClass: DepositAddressCollectionCell.self)
        collectionView?.isPagingEnabled = true
        collectionView?.alwaysBounceHorizontal = (item?.addresses.count ?? 1) > 1
        collectionView?.showsHorizontalScrollIndicator = false
        addSubview(collectionView!)
        collectionView?.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        collectionView?.backgroundColor = .clear
    }

    override func updateView() {
        super.updateView()
//        collectionView?.reloadData()
    }

}

extension DepositCollectionItemView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return item?.addresses.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: DepositAddressCollectionCell.self), for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? DepositAddressCollectionCell, let address = item?.addresses[indexPath.item] {
            cell.bind(address: address, onCopy: { [weak self] in
                self?.item?.onCopy?()
            }, onClose: { [weak self] in
                self?.item?.onClose?()
            })
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width - (scrollView.contentInset.left*2)
        let index = scrollView.contentOffset.x / width
        let roundedIndex = round(index)
        item?.onPageChange?(Int(roundedIndex))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

}
