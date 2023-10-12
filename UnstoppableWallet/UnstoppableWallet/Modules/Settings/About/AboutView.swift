import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: AboutViewModel

    @State private var termsPresented = false
    @State private var linkUrl: URL?

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                HStack(spacing: .margin16) {
                    Image(uiImage: UIImage(named: AppIcon.main.imageName) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous))
                        .frame(width: 72, height: 72)

                    VStack(spacing: .margin8) {
                        Text("settings.about_app.app_name".localized(AppConfig.appName)).themeHeadline1()
                        Text("version".localized(viewModel.appVersion)).themeSubhead2()
                    }
                }
                .padding(.horizontal, .margin24)

                Text("settings.about_app.description".localized(AppConfig.appName, AppConfig.appName))
                    .font(.themeBody)
                    .foregroundColor(.themeBran)
                    .padding(.horizontal, .margin32)
                    .padding(.vertical, .margin12)

                VStack(spacing: .margin32) {
                    if let releaseNotesUrl = viewModel.releaseNotesUrl {
                        ListSection {
                            NavigationRow(destination: {
                                MarkdownModule.gitReleaseNotesMarkdownView(url: releaseNotesUrl, presented: false)
                                    .ignoresSafeArea()
                            }) {
                                Image("circle_information_24").themeIcon()
                                Text("settings.about_app.whats_new".localized).themeBody()
                                Image.disclosureIcon
                            }
                        }
                    }

                    ListSection {
                        NavigationRow(destination: {
                            AppStatusModule.view()
                        }) {
                            Image("app_status_24").themeIcon()
                            Text("app_status.title".localized).themeBody()
                            Image.disclosureIcon
                        }

                        ClickableRow(action: {
                            termsPresented = true
                        }) {
                            Image("unordered_24").themeIcon()
                            Text("terms.title".localized).themeBody()

                            if viewModel.termsAlert {
                                Image("warning_2_20").themeIcon(color: .themeLucian).padding(.trailing, -.margin8)
                            }

                            Image.disclosureIcon
                        }

                        NavigationRow(destination: {
                            PrivacyPolicyView(config: .privacy)
                                .navigationTitle(PrivacyPolicyViewController.Config.privacy.title)
                                .ignoresSafeArea()
                        }) {
                            Image("user_24").themeIcon()
                            Text("settings.privacy".localized).themeBody()
                            Image.disclosureIcon
                        }
                    }

                    ListSection {
                        ClickableRow(action: {
                            linkUrl = URL(string: "https://github.com/\(AppConfig.appGitHubAccount)/\(AppConfig.appGitHubRepository)")
                        }) {
                            Image("github_24").themeIcon()
                            Text("GitHub").themeBody()
                            Image.disclosureIcon
                        }

                        ClickableRow(action: {
                            let account = AppConfig.appTwitterAccount

                            if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
                                UIApplication.shared.open(appUrl)
                            } else {
                                linkUrl = URL(string: "https://twitter.com/\(account)")
                            }
                        }) {
                            Image("twitter_24").themeIcon()
                            Text("Twitter").themeBody()
                            Image.disclosureIcon
                        }

                        ClickableRow(action: {
                            linkUrl = URL(string: AppConfig.appWebPageLink)
                        }) {
                            Image("globe_24").themeIcon()
                            Text("settings.about_app.website".localized).themeBody()
                            Image.disclosureIcon
                        }
                    }
                }
                .padding(.horizontal, .margin16)
            }
            .padding(EdgeInsets(top: .margin24, leading: 0, bottom: .margin32, trailing: 0))
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
    }
}
