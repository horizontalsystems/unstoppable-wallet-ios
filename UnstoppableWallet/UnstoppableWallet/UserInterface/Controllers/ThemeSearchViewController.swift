import UIKit
import ThemeKit

class ThemeSearchViewController: ThemeViewController {
    private let searchController = UISearchController(searchResultsController: nil)
    private var currentFilter: String?

    override public init(gradient: Bool = true) {
        super.init(gradient: gradient)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        definesPresentationContext = true

        navigationItem.searchController = searchController
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .themeOz

            if let leftView = textField.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = .themeGray
            }
        }
    }

    func onUpdate(filter: String?) {
    }

}

extension ThemeSearchViewController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        var filter = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces)

        if filter == "" {
            filter = nil
        }

        if filter != currentFilter {
            currentFilter = filter
            onUpdate(filter: filter)
        }
    }

}
