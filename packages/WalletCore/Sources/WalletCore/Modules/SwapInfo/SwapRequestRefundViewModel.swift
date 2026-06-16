import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
class SwapRequestRefundViewModel: ObservableObject {
    private let swap: Swap
    private let providerInfoManager: SwapProviderInfoManager
    private var cancellables = Set<AnyCancellable>()

    let details: SwapRequestRefundBuilder.Details
    @Published private(set) var contactLinks = [SwapRequestRefundBuilder.ContactLink]()

    init(swap: Swap, providerInfoManager: SwapProviderInfoManager = Core.shared.swapProviderInfoManager) {
        self.swap = swap
        self.providerInfoManager = providerInfoManager
        details = SwapRequestRefundBuilder.details(swap: swap)
        syncContactLinks()

        providerInfoManager.providerInfoUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                Task { @MainActor in
                    self?.syncContactLinks()
                }
            }
            .store(in: &cancellables)
    }

    func copyBody() {
        SwapRequestRefundBuilder.copyBody(details.emailBody)
    }

    func open(contactLink: SwapRequestRefundBuilder.ContactLink) {
        switch contactLink.type {
        case .email:
            let fallbackText = SwapRequestRefundBuilder.shareText(email: contactLink.rawValue, subject: details.emailSubject, body: details.emailBody)

            guard let url = SwapRequestRefundBuilder.mailtoURL(email: contactLink.rawValue, subject: details.emailSubject, body: details.emailBody) else {
                Coordinator.shared.present { _ in ActivityView(activityItems: [fallbackText]) }
                return
            }

            UIApplication.shared.open(url, options: [:]) { opened in
                guard !opened else {
                    return
                }
                Coordinator.shared.present { _ in ActivityView(activityItems: [fallbackText]) }
            }

        case .telegram:
            copyBody()
            guard let urls = SwapRequestRefundBuilder.telegramURLs(contactLink: contactLink) else {
                return
            }

            if let appURL = urls.appURL, UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
            } else {
                Coordinator.shared.present(url: urls.webURL)
            }

        case .twitter, .website:
            if let url = SwapRequestRefundBuilder.safeURL(contactLink: contactLink) {
                Coordinator.shared.present(url: url)
            }
        }
    }

    private func syncContactLinks() {
        contactLinks = SwapRequestRefundBuilder.contactLinks(contacts: providerInfoManager.contacts(providerId: swap.providerId))
    }
}

enum SwapRequestRefundBuilder {
    static func details(swap: Swap) -> Details {
        let swapId = firstNonEmpty([swap.providerSwapId, swap.txHash, swap.uid])
        let amount = AppValue(token: swap.tokenIn, value: swap.amountIn).formattedFull() ?? "\(swap.amountIn) \(swap.tokenIn.coin.code)"
        let refundAddress = swap.refundAddress ?? swap.sourceAddress ?? ""

        return Details(
            swapId: swapId,
            swapIdShort: swapId.shortened,
            amount: amount,
            refundAddress: refundAddress,
            refundAddressShort: refundAddress.shortened,
            emailSubject: "Refund Request - \(swapId)",
            emailBody: emailBody(
                swapId: swapId,
                fromAsset: swap.tokenIn.coin.code,
                toAsset: swap.tokenOut.coin.code,
                amount: amount,
                txHash: swap.txHash ?? ""
            )
        )
    }

    static func emailBody(swapId: String, fromAsset: String, toAsset: String, amount: String, txHash: String) -> String {
        """
        Hello,
        My swap was stopped after the deposit was received. I would like to request a refund.

        Swap ID: \(swapId)
        From: \(fromAsset)
        To: \(toAsset)
        Amount: \(amount)
        Deposit transaction: \(txHash)

        Please let me know if any additional information is required.
        Thank you.
        """
    }

    static func contactLinks(contacts: SwapProviderInfoManager.Contacts?) -> [ContactLink] {
        var links = [ContactLink]()

        if let telegram = contacts?.telegram?.content {
            links.append(.init(type: .telegram, label: "Telegram", value: telegram, rawValue: telegram, icon: "telegram_24"))
        }

        if let twitter = contacts?.twitter?.content {
            links.append(.init(type: .twitter, label: "Twitter", value: twitter, rawValue: twitter, icon: "twitter_24"))
        }

        let email = contacts?.email?.content
        let websiteFromEmail = email.flatMap { safeHTTPSURL($0)?.absoluteString }

        if let email, isValidEmail(email) {
            links.append(.init(type: .email, label: "Email", value: email, rawValue: email, icon: "mail_24"))
        }

        if let website = contacts?.website?.content ?? websiteFromEmail, safeHTTPSURL(website) != nil {
            links.append(.init(type: .website, label: "Website", value: website, rawValue: website, icon: "globe_24"))
        }

        return links
    }

    static func safeURL(contactLink: ContactLink) -> URL? {
        switch contactLink.type {
        case .email:
            return nil
        case .telegram:
            return telegramURLs(contactLink: contactLink)?.webURL
        case .twitter:
            return safeHTTPSURL(contactLink.rawValue, allowedHosts: ["x.com", "twitter.com"])
        case .website:
            return safeHTTPSURL(contactLink.rawValue)
        }
    }

    static func telegramURLs(contactLink: ContactLink) -> TelegramURLs? {
        guard contactLink.type == .telegram else {
            return nil
        }

        return safeTelegramURLs(contactLink.rawValue)
    }

    static func mailtoURL(email: String, subject: String, body: String) -> URL? {
        guard isValidEmail(email) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }

    static func shareText(email: String, subject: String, body: String) -> String {
        """
        To: \(email)
        Subject: \(subject)

        \(body)
        """
    }

    static func copyBody(_ body: String) {
        UIPasteboard.general.setItems(
            [["public.utf8-plain-text": body]],
            options: [.expirationDate: Date().addingTimeInterval(10 * 60)]
        )
        HudHelper.instance.show(banner: .copied)
    }

    private static func firstNonEmpty(_ values: [String?]) -> String {
        values.compactMap { $0?.content }.first ?? ""
    }

    private static func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)

        return parts.count == 2 &&
            !parts[0].isEmpty &&
            parts[1].contains(".") &&
            !parts[1].isEmpty &&
            !trimmed.contains(where: { $0.isWhitespace || $0.isNewline }) &&
            trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: ":/?#&%")) == nil
    }

    private static func safeHTTPSURL(_ rawValue: String, allowedHosts: [String]? = nil) -> URL? {
        guard
            let components = URLComponents(string: rawValue),
            components.scheme?.lowercased() == "https",
            let host = components.host?.lowercased().stripping(prefix: "www."),
            !host.isEmpty,
            let url = components.url
        else {
            return nil
        }

        guard let allowedHosts else {
            return url
        }

        return allowedHosts.contains { allowedHost in
            host == allowedHost || host.hasSuffix(".\(allowedHost)")
        } ? url : nil
    }

    private static func safeTelegramURLs(_ rawValue: String) -> TelegramURLs? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = safeHTTPSURL(trimmed, allowedHosts: ["t.me", "telegram.me"]) {
            return TelegramURLs(appURL: telegramAppURL(webURL: url), webURL: url)
        }

        let lowercased = trimmed.lowercased()
        if lowercased.hasPrefix("t.me/") || lowercased.hasPrefix("telegram.me/") {
            return safeTelegramURLs("https://\(trimmed)")
        }

        let username = trimmed.stripping(prefix: "@")
        guard username.range(of: "^[A-Za-z0-9_]{5,32}$", options: .regularExpression) != nil else {
            return nil
        }

        guard let webURL = URL(string: "https://t.me/\(username)") else {
            return nil
        }

        return TelegramURLs(appURL: telegramAppURL(username: username), webURL: webURL)
    }

    private static func telegramAppURL(webURL: URL) -> URL? {
        guard
            let components = URLComponents(url: webURL, resolvingAgainstBaseURL: false),
            let username = components.path.split(separator: "/").first.map(String.init),
            username.range(of: "^[A-Za-z0-9_]{5,32}$", options: .regularExpression) != nil
        else {
            return nil
        }

        return telegramAppURL(username: username)
    }

    private static func telegramAppURL(username: String) -> URL? {
        URL(string: "tg://resolve?domain=\(username)")
    }
}

extension SwapRequestRefundBuilder {
    struct Details {
        let swapId: String
        let swapIdShort: String
        let amount: String
        let refundAddress: String
        let refundAddressShort: String
        let emailSubject: String
        let emailBody: String
    }

    struct ContactLink: Identifiable, Equatable {
        let type: ContactType
        let label: String
        let value: String
        let rawValue: String
        let icon: String

        var id: String {
            "\(type)-\(rawValue)"
        }
    }

    struct TelegramURLs: Equatable {
        let appURL: URL?
        let webURL: URL
    }

    enum ContactType {
        case email
        case telegram
        case twitter
        case website
    }
}

private extension String {
    var content: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
