import Foundation
import Observation
import OpenAPIRuntime

enum TravelTab: Hashable {
    case search
    case settings
}

enum Endpoint: String, Identifiable, Hashable {
    case origin
    case destination

    var id: String { rawValue }
    var title: String { self == .origin ? "Откуда" : "Куда" }
}

enum AppPresentation: Identifiable {
    case cityPicker(Endpoint)

    var id: String {
        switch self {
        case .cityPicker(let endpoint): "city-\(endpoint.id)"
        }
    }
}

enum TravelFailure: String, Identifiable {
    case server
    case offline

    var id: String { rawValue }
    var title: String { self == .server ? "Ошибка сервера" : "Нет интернета" }
    var imageName: String { self == .server ? "ServerError" : "NoInternet" }
}

struct TravelPlace: Identifiable, Hashable {
    let city: String
    let station: String
    let stationCode: String

    var id: String { stationCode }
    var title: String {
        if station.localizedCaseInsensitiveCompare(city) == .orderedSame
            || station.lowercased().hasPrefix(city.lowercased() + " (") {
            return station
        }
        return "\(city) (\(station))"
    }
}

struct TravelCity: Identifiable, Hashable {
    let name: String
    let code: String
    let stations: [TravelStation]

    var id: String { code }
}

struct TravelStation: Identifiable, Hashable {
    let name: String
    let code: String

    var id: String { code }
}

struct TravelRoute: Identifiable {
    let id = UUID()
    let departure: String
    let arrival: String
    let carrier: String
    let carrierContacts: String?
    let carrierEmail: String?
    let carrierPhone: String?
    let carrierURL: String?
    let number: String
    let transport: String
    let duration: Int
    let date: String
    let hasTransfers: Bool
    let transferTitle: String?

    var carrierLogoName: String? {
        let name = carrier.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if name.contains("ржд") || name.contains("rzd") { return "RZD" }
        if name.contains("фгк") || name.contains("fgk") || name.contains("federal freight") { return "FGK" }
        if name.contains("урал логист") || name.contains("ural logistic") { return "UralLogistics" }
        return nil
    }

    var durationText: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours == 0 { return "\(minutes) мин" }
        if minutes > 0 { return "\(hours) ч \(minutes) мин" }
        let suffix: String
        switch (hours % 100, hours % 10) {
        case (11...14, _): suffix = "часов"
        case (_, 1): suffix = "час"
        case (_, 2...4): suffix = "часа"
        default: suffix = "часов"
        }
        return "\(hours) \(suffix)"
    }
}

enum DeparturePeriod: String, CaseIterable, Identifiable {
    case morning = "Утро"
    case day = "День"
    case evening = "Вечер"
    case night = "Ночь"

    var id: String { rawValue }
    var hours: Range<Int> {
        switch self {
        case .morning: 6..<12
        case .day: 12..<18
        case .evening: 18..<24
        case .night: 0..<6
        }
    }
    var interval: String {
        switch self {
        case .morning: "06:00 - 12:00"
        case .day: "12:00 - 18:00"
        case .evening: "18:00 - 00:00"
        case .night: "00:00 - 06:00"
        }
    }
}

@MainActor
@Observable
final class TravelScheduleModel {
    var selectedTab: TravelTab = .search
    var presentation: AppPresentation?
    var cities: [TravelCity] = []
    var origin: TravelPlace?
    var destination: TravelPlace?
    var routes: [TravelRoute] = []
    var isLoadingCities = false
    var isLoading = false
    var showRoutes = false
    var transferChoice: Bool?
    var selectedPeriods = Set<DeparturePeriod>()
    var failure: TravelFailure?
    private let stationsService: (any StationsListServiceProtocol)?
    private let routesService: (any ScheduleBetweenStationsServiceProtocol)?
    private var citiesRequestID: UUID?
    private var routesRequestID: UUID?
    private var hasLoadedRoutes = false

    init(
        stationsService: (any StationsListServiceProtocol)? = nil,
        routesService: (any ScheduleBetweenStationsServiceProtocol)? = nil
    ) {
        self.stationsService = stationsService
        self.routesService = routesService
    }

    var allowsTransfers: Bool { transferChoice ?? true }
    var hasActiveFilters: Bool { !selectedPeriods.isEmpty || transferChoice != nil }
    var routeTitle: String {
        [origin?.title, destination?.title].compactMap { $0 }.joined(separator: " → ")
    }

    var filteredRoutes: [TravelRoute] {
        routes.filter { route in
            guard allowsTransfers || !route.hasTransfers else { return false }
            guard !selectedPeriods.isEmpty else { return true }
            guard let hour = Int(route.departure.prefix(2)) else { return false }
            return selectedPeriods.contains { $0.hours.contains(hour) }
        }
    }

    func loadCities() async {
        guard cities.isEmpty else { return }
        let requestID = UUID()
        citiesRequestID = requestID
        isLoadingCities = true
        failure = nil
        defer {
            if citiesRequestID == requestID { isLoadingCities = false }
        }

        do {
            let service = try stationsService ?? APIClientFactory.makeStationsService()
            let response = try await service.getStations()
            let loadedCities = try await Self.makeCities(from: response)
            try Task.checkCancellation()
            guard citiesRequestID == requestID else { return }
            cities = loadedCities
        } catch {
            guard !Task.isCancelled, citiesRequestID == requestID else { return }
            failure = Self.failure(for: error)
        }
    }

    func select(_ place: TravelPlace, for endpoint: Endpoint) {
        if endpoint == .origin {
            origin = place
        } else {
            destination = place
        }
    }

    func swapPlaces() {
        swap(&origin, &destination)
    }

    func prepareSearch() {
        routesRequestID = nil
        routes = []
        failure = nil
        hasLoadedRoutes = false
        selectedPeriods = []
        transferChoice = nil
        showRoutes = true
    }

    func loadRoutes() async {
        guard !hasLoadedRoutes, let origin, let destination else { return }
        let requestID = UUID()
        routesRequestID = requestID
        isLoading = true
        failure = nil
        defer {
            if routesRequestID == requestID { isLoading = false }
        }

        do {
            let service = try routesService ?? APIClientFactory.makeRoutesService()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd"
            let response = try await service.getSchedule(
                from: origin.stationCode,
                to: destination.stationCode,
                date: formatter.string(from: Date()),
                transfers: true
            )
            let segments = response.segments ?? []
            var mappedRoutes: [TravelRoute] = []
            mappedRoutes.reserveCapacity(segments.count)
            for segment in segments {
                try Task.checkCancellation()
                mappedRoutes.append(Self.makeRoute(from: segment))
            }
            guard routesRequestID == requestID else { return }
            routes = mappedRoutes
            hasLoadedRoutes = true
        } catch {
            guard !Task.isCancelled, routesRequestID == requestID else { return }
            failure = Self.failure(for: error)
        }
    }

    private static func time(from value: String?) -> String {
        guard let value else { return "—" }
        let parts = value.split(whereSeparator: { $0 == "T" || $0 == " " })
        guard !parts.isEmpty else { return "—" }
        let clock = String((parts.count > 1 ? parts[1] : parts[0]).prefix(5))
        let components = clock.split(separator: ":")
        guard clock.count == 5, components.count == 2,
              let hour = Int(components[0]), (0..<24).contains(hour),
              let minute = Int(components[1]), (0..<60).contains(minute) else { return "—" }
        return clock
    }

    private static func makeRoute(from segment: Components.Schemas.Segment) -> TravelRoute {
        let departure = time(from: segment.departure)
        let arrival = time(from: segment.arrival)
        let thread = segment.thread ?? segment.details?.compactMap(\.thread).first
        let carrierInfo = thread?.carrier
        let carrier = carrierInfo?.title ?? "Перевозчик"
        let number = thread?.number ?? ""
        let transport = thread?.transport_type ?? "Поезд"
        let seconds = segment.duration ?? segment.details?.reduce(0) { $0 + ($1.duration ?? 0) } ?? 0
        let duration = Int(max(0, seconds) / 60)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = segment.departure.flatMap { dateFormatter.date(from: String($0.prefix(10))) }
        dateFormatter.dateFormat = "d MMMM"
        let transferTitle = segment.transfers?.compactMap(\.title).joined(separator: ", ")
        return TravelRoute(
            departure: departure,
            arrival: arrival,
            carrier: carrier,
            carrierContacts: carrierInfo?.contacts,
            carrierEmail: carrierInfo?.email,
            carrierPhone: carrierInfo?.phone,
            carrierURL: carrierInfo?.url,
            number: number,
            transport: transport,
            duration: duration,
            date: date.map(dateFormatter.string(from:)) ?? "",
            hasTransfers: segment.has_transfers ?? false,
            transferTitle: transferTitle?.isEmpty == false ? transferTitle : nil
        )
    }

    nonisolated private static func makeCities(from response: StationsList) async throws -> [TravelCity] {
        let settlements = (response.countries ?? []).flatMap { $0.regions ?? [] }
            .flatMap { $0.settlements ?? [] }

        return try settlements.compactMap { settlement in
            try Task.checkCancellation()
            guard let name = settlement.title,
                  let cityCode = settlement.codes?.yandex_code else { return nil }

            let stations = (settlement.stations ?? []).compactMap { station -> TravelStation? in
                guard let name = station.title,
                      let code = station.codes?.yandex_code ?? station.code else { return nil }
                return TravelStation(name: name, code: code)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            guard !stations.isEmpty else { return nil }
            return TravelCity(name: name, code: cityCode, stations: stations)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func failure(for error: Error) -> TravelFailure? {
        var underlyingError = error
        for _ in 0..<4 {
            if underlyingError is CancellationError { return nil }
            if let urlError = underlyingError as? URLError {
                if urlError.code == .cancelled { return nil }
                let offlineCodes: Set<URLError.Code> = [
                    .notConnectedToInternet,
                    .networkConnectionLost,
                    .cannotConnectToHost,
                    .cannotFindHost,
                    .dnsLookupFailed,
                    .dataNotAllowed,
                    .internationalRoamingOff
                ]
                return offlineCodes.contains(urlError.code) ? .offline : .server
            }
            if let clientError = underlyingError as? ClientError {
                underlyingError = clientError.underlyingError
                continue
            }
            let wrappedError = underlyingError as NSError
            guard let error = wrappedError.userInfo[NSUnderlyingErrorKey] as? Error else { break }
            underlyingError = error
        }
        return .server
    }
}
