import SwiftUI

struct BackupSelectContentView: View {
    @ObservedObject var viewModel: BackupViewModel
    @StateObject private var contentViewModel: BackupSelectContentViewModel
    @Binding var path: NavigationPath

    init(viewModel: BackupViewModel, path: Binding<NavigationPath>) {
        self.viewModel = viewModel
        _contentViewModel = StateObject(wrappedValue: BackupSelectContentViewModel(selectedAccountIds: viewModel.selectedAccountIds))
        _path = path
    }

    var body: some View {
        BackupContentListView(
            description: "backup_content.description.backup".localized,
            walletItems: contentViewModel.walletItems,
            dataItems: contentViewModel.dataItems,
            selectedWalletIds: $contentViewModel.selectedWalletIds,
            selectedDataSections: $contentViewModel.selectedDataSections,
            buttonTitle: "button.next".localized,
            onAction: {
                viewModel.setSelectedAccountIds(contentViewModel.selectedWalletIds)
                viewModel.setSelectedDataSections(contentViewModel.selectedDataSections)
                path.append(BackupModule.Step.form)
            }
        )
        .navigationTitle("backup_content.title.create".localized)
    }
}
