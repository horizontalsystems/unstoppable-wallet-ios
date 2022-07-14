import UIKit
import ThemeKit

class ThemeSearchViewController: KeyboardAwareViewController {
    private let searchController = UISearchController(searchResultsController: nil)
    private var currentFilter: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.showsCancelButton = false
        searchController.searchResultsUpdater = self
        searchController.delegate = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func dismiss(animated flag: Bool, completion: (() -> ())? = nil) {
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

    func onUpdate(filter: String?) {
    }

}

extension ThemeSearchViewController: UISearchControllerDelegate {

    public func didPresentSearchController(_ searchController: UISearchController) {
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
            onUpdate(filter: filter)
        }
    }

}
