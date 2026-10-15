import SwiftUI

struct CityPickerView: View {
    @Bindable var model: TravelScheduleModel
    let endpoint: Endpoint
    let onSelect: (TravelPlace) -> Void
    let onClose: () -> Void
    @State private var query = ""

    private var cities: [TravelCity] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return model.cities }
        return model.cities.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TravelNavigationHeader(title: "Выбор города", onBack: onClose)
                if let failure = model.citiesFailure {
                    FailureView(failure: failure)
                } else if model.isLoadingCities {
                    ProgressView("Загружаем города")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SearchField(query: $query)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    if cities.isEmpty {
                        EmptyResultView(title: "Город не найден")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(cities) { city in
                                    NavigationLink(value: city) {
                                        PlaceRow(title: city.name)
                                    }
                                }
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
            }
            .background(TravelStyle.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: TravelCity.self) { city in
                StationPickerView(city: city, onSelect: onSelect)
            }
        }
        .foregroundStyle(TravelStyle.text)
        .buttonStyle(.plain)
        .task { await model.loadCities() }
    }
}

private struct StationPickerView: View {
    let city: TravelCity
    let onSelect: (TravelPlace) -> Void
    @State private var query = ""

    private var stations: [TravelStation] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return city.stations }
        return city.stations.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TravelNavigationHeader(title: "Выбор станции")
            SearchField(query: $query)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            if stations.isEmpty {
                EmptyResultView(title: "Станция не найдена")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(stations) { station in
                            Button {
                                onSelect(TravelPlace(
                                    city: city.name,
                                    station: station.name,
                                    stationCode: station.code
                                ))
                            } label: {
                                PlaceRow(title: station.name)
                            }
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .buttonStyle(.plain)
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PlaceRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 17))
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundStyle(TravelStyle.text)
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}

private struct SearchField: View {
    @Binding var query: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(TravelStyle.gray)
            TextField("Введите запрос", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(TravelStyle.gray)
                }
                .accessibilityLabel("Очистить поиск")
            }
        }
        .font(.system(size: 17))
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.12) : Color(red: 239 / 255, green: 239 / 255, blue: 240 / 255),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}
