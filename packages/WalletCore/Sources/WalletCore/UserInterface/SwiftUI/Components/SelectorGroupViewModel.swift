import Combine
import Foundation

final class SelectorGroupsViewModel: ObservableObject {
    @Published private(set) var groupStates: [String: Set<String>] = [:]

    func append(id: String, initialSelection: Set<String> = []) {
        groupStates[id] = initialSelection
    }

    func isSelected(_ itemId: String, in groupId: String) -> Bool {
        groupStates[groupId]?.contains(itemId) ?? false
    }

    func toggleSelection(_ itemId: String, in group: GroupSelector) {
        guard var currentSelection = groupStates[group.id] else { return }

        switch group.type {
        case .single:
            if currentSelection.contains(itemId) {
                if group.requireSelection, currentSelection.count == 1 {
                    return
                }
                currentSelection.removeAll()
            } else {
                currentSelection = [itemId]
            }

        case .multi:
            if currentSelection.contains(itemId) {
                if group.requireSelection, currentSelection.count == 1 {
                    return
                }
                currentSelection.remove(itemId)
            } else {
                currentSelection.insert(itemId)
            }
        }

        groupStates[group.id] = currentSelection
    }

    func getSelection(_ groupId: String) -> Set<String> {
        groupStates[groupId] ?? []
    }

    func setSelection(_ selection: Set<String>, for groupId: String) {
        groupStates[groupId] = selection
    }

    func clearSelection(_ groupId: String) {
        groupStates[groupId]?.removeAll()
    }

    func removeGroup(_ id: String) {
        groupStates.removeValue(forKey: id)
    }
}

struct GroupSelector: Identifiable {
    let id: String
    let items: [GroupSelectorItem]
    let type: SelectionType
    let style: Style
    let requireSelection: Bool

    init(
        id: String = UUID().description,
        items: [GroupSelectorItem],
        type: SelectionType = .multi,
        style: Style = .leadingCheckbox,
        requireSelection: Bool = false
    ) {
        self.id = id
        self.items = items
        self.type = type
        self.style = style
        self.requireSelection = requireSelection
    }

    enum SelectionType {
        case multi
        case single
    }

    enum Style {
        case switcher
        case leadingCheckbox
        case trailingCheckbox
    }
}

struct GroupSelectorItem: Identifiable, Hashable {
    let id: String
    let text: CustomStringConvertible?
    let description: CustomStringConvertible?

    init(id: String, text: CustomStringConvertible? = nil, description: CustomStringConvertible? = nil) {
        self.id = id
        self.text = text
        self.description = description
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
