import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: AboutViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                if let releaseNotesUrl = viewModel.releaseNotesUrl {
                    ListSection {
                        NavigationRow(spacing: .margin8, destination: {
                            MarkdownModule.gitReleaseNotesMarkdownView(url: releaseNotesUrl, presented: false)
                                .onFirstAppear { stat(page: .aboutApp, event: .open(page: .whatsNews)) }
                                .ignoresSafeArea()
                        }) {
                            HStack(spacing: .margin16) {
                                Image("circle_information_24").themeIcon()
                                Text("settings.about_app.app_version".localized).textBody()
                            }
                            Spacer()
                            Text(viewModel.appVersion).textSubhead1()
                            Image.disclosureIcon
                        }
                    }
                }

                ListSection {
                    NavigationRow(destination: {
                        AppStatusView()
                            .onFirstAppear { stat(page: .aboutApp, event: .open(page: .appStatus)) }
                    }) {
                        Image("app_status_24").themeIcon()
                        Text("app_status.title".localized).themeBody()
                        Image.disclosureIcon
                    }

                    ClickableRow(action: {
                        Coordinator.shared.present { isPresented in
                            TermsView(isPresented: isPresented)
                        }
                        stat(page: .aboutApp, event: .open(page: .terms))
                    }) {
                        Image("unordered_24").themeIcon()
                        Text("terms.title".localized).themeBody()

                        if viewModel.termsAlert {
                            Image("warning_2_20").themeIcon(color: .themeLucian).padding(.trailing, -.margin8)
                        }

                        Image.disclosureIcon
                    }
                }

                ListSection {
                    ClickableRow(action: {
                        Coordinator.shared.present(url: URL(string: "https://github.com/\(AppConfig.appGitHubAccount)/\(AppConfig.appGitHubRepository)"))
                        stat(page: .aboutApp, event: .open(page: .externalGithub))
                    }) {
                        Image("github_24").themeIcon()
                        Text("GitHub").themeBody()
                        Image.disclosureIcon
                    }

                    ClickableRow(action: {
                        Coordinator.shared.present(url: URL(string: AppConfig.appWebPageLink))
                        stat(page: .aboutApp, event: .open(page: .externalWebsite))
                    }) {
                        Image("globe_24").themeIcon()
                        Text("settings.about_app.website".localized).themeBody()
                        Image.disclosureIcon
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("settings.about_app.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
