import Combine
import HsExtensions
import ThemeKit
import UIKit

class ThemeSearchViewController: KeyboardAwareViewController {
    let searchController = UISearchController(searchResultsController: nil)
    private let automaticallyShowsCancelButton: Bool

    private var currentFilter: String?

    @PostPublished var filter: String?

    init(scrollViews: [UIScrollView], automaticallyShowsCancelButton: Bool = false, accessoryView: UIView? = nil) {
        self.automaticallyShowsCancelButton = automaticallyShowsCancelButton

        super.init(scrollViews: scrollViews, accessoryView: accessoryView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsCancelButton = automaticallyShowsCancelButton
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.setValue("button.cancel".localized, forKey: "cancelButtonText")
        searchController.searchBar.placeholder = "placeholder.search".localized

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if searchController.isActive {
            searchController.dismiss(animated: false)
        }

        super.dismiss(animated: flag, completion: completion)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .themeLeah

            if let leftView = textField.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = .themeGray
            }
        }
    }
}

extension ThemeSearchViewController: UISearchControllerDelegate {
    public func didPresentSearchController(_: UISearchController) {
        DispatchQueue.main.async {
            self.searchController.searchBar.becomeFirstResponder()
        }
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

            self.filter = filter
        }
    }
}
