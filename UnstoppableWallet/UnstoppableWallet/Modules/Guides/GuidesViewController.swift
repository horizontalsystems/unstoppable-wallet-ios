import UIKit
import SnapKit
import ThemeKit

class GuidesViewController: ThemeViewController {
    private let delegate: IGuidesViewDelegate

    private let horizontalInset: CGFloat = .margin4x
    private let interitemSpacing: CGFloat = .margin2x
    private let lineSpacing: CGFloat = .margin3x

    private let layout = UICollectionViewFlowLayout()
    private let collectionView: UICollectionView

    private var viewItems = [GuideViewItem]()

    init(delegate: IGuidesViewDelegate) {
        self.delegate = delegate

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init()

        tabBarItem = UITabBarItem(title: "guides.tab_bar_item".localized, image: UIImage(named: "Guides Tab Bar"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "guides.title".localized

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear

        collectionView.register(GuideCell.self, forCellWithReuseIdentifier: String(describing: GuideCell.self))

        delegate.onLoad()
    }

}

extension GuidesViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GuideCell.self), for: indexPath)
    }

}

extension GuidesViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GuideCell {
            cell.bind(viewItem: viewItems[indexPath.item])
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate.onTapGuide(index: indexPath.item)
    }

}

extension GuidesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat

        if viewItems[indexPath.item].large {
            width = collectionView.width - horizontalInset * 2
        } else {
            width = (collectionView.width - horizontalInset * 2 - interitemSpacing) / 2
        }

        return CGSize(width: width, height: 220)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        interitemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        lineSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: lineSpacing, left: horizontalInset, bottom: lineSpacing, right: horizontalInset)
    }

}

extension GuidesViewController: IGuidesView {

    func set(viewItems: [GuideViewItem]) {
        self.viewItems = viewItems
    }

}
