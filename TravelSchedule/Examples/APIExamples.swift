#if DEBUG
import Foundation

enum APIExamples {
    static func run() async {
        let client: Client
        let apiKey: String

        do {
            client = try APIClientFactory.makeClient()
            apiKey = try APIConfiguration.load().apiKey
        } catch {
            print("Проверьте настройки API в Secrets.xcconfig")
            return
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Moscow")
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: Date())
        var routeUID: String?

        guard !Task.isCancelled else { return }
        do {
            let service = NearestStationsService(client: client, apiKey: apiKey)
            let response = try await service.getNearestStations(lat: 59.864177, lng: 30.319163, distance: 10)
            print("Ближайшие станции: \(response.stations?.count ?? 0)")
        } catch {
            print("Не удалось получить ближайшие станции")
        }

        guard !Task.isCancelled else { return }
        do {
            let service = ScheduleBetweenStationsService(client: client, apiKey: apiKey)
            let response = try await service.getSchedule(from: "c146", to: "c213", date: date, transfers: true)
            print("Маршруты между городами: \(response.segments?.count ?? 0)")
        } catch {
            print("Не удалось получить маршруты между городами")
        }

        guard !Task.isCancelled else { return }
        do {
            let service = StationScheduleService(client: client, apiKey: apiKey)
            let response = try await service.getSchedule(station: "s9600213", date: date)
            routeUID = response.schedule?.compactMap { $0.thread?.uid }.first { !$0.isEmpty }
            print("Рейсы на станции: \(response.schedule?.count ?? 0)")
        } catch {
            print("Не удалось получить расписание станции")
        }

        guard !Task.isCancelled else { return }
        if let routeUID {
            do {
                let service = RouteStationsService(client: client, apiKey: apiKey)
                let response = try await service.getRoute(uid: routeUID, date: date)
                print("Остановки рейса: \(response.stops?.count ?? 0)")
            } catch {
                print("Не удалось получить остановки рейса")
            }
        } else {
            print("В расписании нет рейса для проверки остановок")
        }

        guard !Task.isCancelled else { return }
        do {
            let service = NearestSettlementService(client: client, apiKey: apiKey)
            let response = try await service.getNearestSettlement(lat: 59.864177, lng: 30.319163)
            print("Ближайший город: \(response.title ?? "не найден")")
        } catch {
            print("Не удалось получить ближайший город")
        }

        guard !Task.isCancelled else { return }
        do {
            let service = CarrierService(client: client, apiKey: apiKey)
            let response = try await service.getCarrier(code: "112")
            print("Перевозчик: \(response.carrier?.title ?? response.carriers?.first?.title ?? "не найден")")
        } catch {
            print("Не удалось получить информацию о перевозчике")
        }

        guard !Task.isCancelled else { return }
        do {
            let service = StationsListService(client: client, apiKey: apiKey)
            let response = try await service.getStations()
            print("Страны в списке станций: \(response.countries?.count ?? 0)")
        } catch {
            print("Не удалось получить список станций")
        }

        guard !Task.isCancelled else { return }
        do {
            let service = CopyrightService(client: client, apiKey: apiKey)
            let response = try await service.getCopyright()
            print("Копирайт: \(response.copyright.text ?? "не указан")")
        } catch {
            print("Не удалось получить копирайт")
        }
    }
}
#endif
