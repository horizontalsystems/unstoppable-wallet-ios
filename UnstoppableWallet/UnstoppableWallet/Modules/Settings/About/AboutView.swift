import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: AboutViewModel

    @State private var termsPresented = false
    @State private var linkUrl: URL?

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
                        AppStatusModule.view()
                            .onFirstAppear { stat(page: .aboutApp, event: .open(page: .appStatus)) }
                    }) {
                        Image("app_status_24").themeIcon()
                        Text("app_status.title".localized).themeBody()
                        Image.disclosureIcon
                    }

                    ClickableRow(action: {
                        stat(page: .aboutApp, event: .open(page: .terms))
                        termsPresented = true
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
                        stat(page: .aboutApp, event: .open(page: .externalGithub))
                        linkUrl = URL(string: "https://github.com/\(AppConfig.appGitHubAccount)/\(AppConfig.appGitHubRepository)")
                    }) {
                        Image("github_24").themeIcon()
                        Text("GitHub").themeBody()
                        Image.disclosureIcon
                    }

                    ClickableRow(action: {
                        stat(page: .aboutApp, event: .open(page: .externalWebsite))
                        linkUrl = URL(string: AppConfig.appWebPageLink)
                    }) {
                        Image("globe_24").themeIcon()
                        Text("settings.about_app.website".localized).themeBody()
                        Image.disclosureIcon
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            .sheet(isPresented: $termsPresented) {
                TermsModule.view()
                    .ignoresSafeArea()
            }
            .sheet(item: $linkUrl) { url in
                SFSafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle("settings.about_app.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
