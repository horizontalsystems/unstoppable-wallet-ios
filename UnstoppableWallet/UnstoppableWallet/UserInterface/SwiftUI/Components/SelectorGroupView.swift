import SwiftUI

struct SelectorGroupView: View {
    let group: GroupSelector
    @StateObject private var viewModel: SelectorGroupsViewModel

    init(group: GroupSelector, viewModel: SelectorGroupsViewModel? = nil) {
        self.group = group

        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            let localViewModel = SelectorGroupsViewModel()
            localViewModel.append(id: group.id, initialSelection: [])
            _viewModel = StateObject(wrappedValue: localViewModel)
        }
    }

    var body: some View {
        ListSection {
            ForEach(group.items) { item in
                cellView(for: item)
            }
        }
        .themeListStyle(.bordered)
    }

    @ViewBuilder
    private func cellView(for item: GroupSelectorItem) -> some View {
        switch group.style {
        case .switcher:
            switcherCell(for: item)
        case .leadingCheckbox:
            checkboxCell(for: item, leading: true)
        case .trailingCheckbox:
            checkboxCell(for: item, leading: false)
        }
    }

    private func switcherCell(for item: GroupSelectorItem) -> some View {
        let isSelected = viewModel.isSelected(item.id, in: group.id)

        return Cell(
            style: .secondary,
            middle: {
                MultiText(title: item.text, subtitle: item.description)
            },
            right: {
                Toggle(
                    isOn: Binding(
                        get: { isSelected },
                        set: { _ in
                            viewModel.toggleSelection(item.id, in: group)
                        }
                    )
                ) {}
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
            }
        )
    }

    @ViewBuilder
    private func checkboxCell(for item: GroupSelectorItem, leading: Bool) -> some View {
        let isSelected = viewModel.isSelected(item.id, in: group.id)

        Group {
            if leading {
                Cell(
                    style: .secondary,
                    left: {
                        checkboxImage(isSelected: isSelected)
                    },
                    middle: {
                        MultiText(subtitle: item.description)
                    },
                )
            } else {
                Cell(
                    style: .secondary,
                    middle: {
                        MultiText(title: item.text, subtitle: item.description)
                    },
                    right: {
                        checkboxImage(isSelected: isSelected)
                    }
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.linear(duration: 0.2)) {
                viewModel.toggleSelection(item.id, in: group)
            }
        }
    }

    @ViewBuilder
    private func checkboxImage(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .themeYellow : .themeGray)
            .font(.system(size: 24))
    }
}
