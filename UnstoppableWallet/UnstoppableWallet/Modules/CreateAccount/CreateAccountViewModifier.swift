import SwiftUI

struct CreateAccountViewModifier: ViewModifier {
    @ObservedObject var viewModel: CreateAccountViewModifierModel
    var onCreate: ((Account) -> Void)?

    @State private var backupAccount: Account?

    init(viewModel: CreateAccountViewModifierModel, onCreate: ((Account) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onCreate = onCreate
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.termsPresented) {
                TermsView(isPresented: $viewModel.termsPresented) {
                    viewModel.createPresented = true
                }
            }
            .sheet(isPresented: $viewModel.createPresented) {
                CreateAccountView(isPresented: $viewModel.createPresented) { account in
                    if let onCreate {
                        onCreate(account)
                    } else {
                        viewModel.createPresented = false
                        backupAccount = account
                    }
                }
            }
            .modifier(BackupRequiredViewModifier.backupPromptAfterCreate(account: $backupAccount))
    }
}
