import SwiftUI

struct CarrierInfoView: View {
    let route: TravelRoute

    var body: some View {
        VStack(spacing: 0) {
            TravelNavigationHeader(title: "Информация о перевозчике")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        if let name = route.carrierLogoName {
                            Image(name).resizable().scaledToFit()
                        } else {
                            Image(systemName: "tram.fill")
                                .resizable().scaledToFit()
                                .foregroundStyle(TravelStyle.blue)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 104)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24))
                    .accessibilityHidden(true)

                    Text(route.carrier)
                        .font(.system(size: 24, weight: .bold))
                    VStack(alignment: .leading, spacing: 0) {
                        contact("E-mail", value: route.carrierEmail, makeURL: CarrierLink.email)
                        contact("Телефон", value: route.carrierPhone, makeURL: CarrierLink.phone)
                        if let website = nonempty(route.carrierURL) {
                            contact("Сайт", value: website, makeURL: CarrierLink.website)
                        }
                        if nonempty(route.carrierEmail) == nil,
                           nonempty(route.carrierPhone) == nil,
                           let contacts = nonempty(route.carrierContacts) {
                            Text(Self.plainContacts(contacts)).font(.system(size: 17))
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func contact(_ title: String, value: String?, makeURL: (String) -> URL?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 17))
            if let value = nonempty(value), let url = makeURL(value) {
                Link(value, destination: url)
                    .font(.system(size: 12))
                    .foregroundStyle(TravelStyle.blue)
            } else {
                Text(nonempty(value) ?? "Не указан")
                    .font(.system(size: 12))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
    }

    static func plainContacts(_ value: String) -> String {
        value
            .replacingOccurrences(of: "(?i)<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private func nonempty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}

enum CarrierLink {
    static func website(_ value: String) -> URL? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        let address = value.contains(":") ? value : "https://" + value
        guard let url = URL(string: address),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, host.contains("."),
              url.user == nil, url.password == nil else { return nil }
        return url
    }

    static func email(_ value: String) -> URL? {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."),
              value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = value
        return components.url
    }

    static func phone(_ value: String) -> URL? {
        let allowed = CharacterSet(charactersIn: "+0123456789 ()-.")
        guard value.rangeOfCharacter(from: allowed.inverted) == nil else { return nil }
        let number = value.filter { "+0123456789".contains($0) }
        guard number.contains(where: { $0.isNumber }),
              !number.dropFirst().contains("+") else { return nil }
        return URL(string: "tel:" + number)
    }
}
