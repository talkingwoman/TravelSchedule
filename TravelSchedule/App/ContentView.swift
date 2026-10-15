import SwiftUI

enum TravelStyle {
    static let blue = Color(red: 55 / 255, green: 114 / 255, blue: 231 / 255)
    static let gray = Color(red: 174 / 255, green: 175 / 255, blue: 180 / 255)
    static let card = Color(red: 238 / 255, green: 238 / 255, blue: 238 / 255)
    static let red = Color(red: 245 / 255, green: 107 / 255, blue: 108 / 255)
    static let black = Color(red: 26 / 255, green: 27 / 255, blue: 34 / 255)
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
            : .white
    })
    static let text = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
    })
}

struct ContentView: View {
    @State private var model = TravelScheduleModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            TabView(selection: $model.selectedTab) {
                NavigationStack {
                    MainSearchView(model: model)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            TravelTabBar(selection: $model.selectedTab)
                        }
                        .navigationDestination(isPresented: $model.showRoutes) {
                            RouteListView(model: model)
                        }
                }
                .tag(TravelTab.search)

                NamedPlaceholderView(title: "Настройки")
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        TravelTabBar(selection: $model.selectedTab)
                    }
                    .tag(TravelTab.settings)
            }
            .toolbar(.hidden, for: .tabBar)
            .allowsHitTesting(model.presentation == nil)
            .accessibilityHidden(model.presentation != nil)

            if case .cityPicker(let endpoint) = model.presentation {
                CityPickerView(model: model, endpoint: endpoint) { place in
                    model.select(place, for: endpoint)
                    model.presentation = nil
                } onClose: {
                    model.presentation = nil
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(TravelStyle.background.ignoresSafeArea())
                .accessibilityAddTraits(.isModal)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .background(TravelStyle.background.ignoresSafeArea())
        .foregroundStyle(TravelStyle.text)
        .tint(TravelStyle.blue)
        .animation(.spring(response: 0.42, dampingFraction: 0.9), value: model.presentation?.id)
    }
}

private struct TravelTabBar: View {
    @Binding var selection: TravelTab

    var body: some View {
        HStack(spacing: 0) {
            tab(.search, symbol: "arrow.up.message.fill", title: "Поиск")
            tab(.settings, symbol: "gearshape.fill", title: "Настройки")
        }
        .frame(height: 49)
        .background(TravelStyle.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(TravelStyle.gray.opacity(0.3)).frame(height: 0.5)
        }
    }

    private func tab(_ tab: TravelTab, symbol: String, title: String) -> some View {
        Button { selection = tab } label: {
            Image(systemName: symbol)
                .font(.system(size: 28))
                .foregroundStyle(selection == tab ? TravelStyle.text : TravelStyle.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }
}

private struct MainSearchView: View {
    @Bindable var model: TravelScheduleModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(spacing: 0) {
                        placeButton(for: .origin, place: model.origin)
                        placeButton(for: .destination, place: model.destination)
                    }
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    Button(action: model.swapPlaces) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(TravelStyle.blue)
                            .frame(width: 36, height: 36)
                            .background(.white, in: Circle())
                            .frame(width: 36, height: 48)
                    }
                    .accessibilityLabel("Поменять местами города")
                }
                .padding(16)
                .background(TravelStyle.blue, in: RoundedRectangle(cornerRadius: 20))

                if model.origin != nil && model.destination != nil {
                    Button(action: model.prepareSearch) {
                        PrimaryActionLabel(title: "Найти").frame(width: 150)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 208)
        }
        .buttonStyle(.plain)
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func placeButton(for endpoint: Endpoint, place: TravelPlace?) -> some View {
        Button {
            model.presentation = .cityPicker(endpoint)
        } label: {
            Text(place?.title ?? endpoint.title)
                .font(.system(size: 17))
                .foregroundStyle(place == nil ? TravelStyle.gray : TravelStyle.black)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(endpoint.title)
        .accessibilityValue(place?.title ?? "Не выбрано")
    }
}

private struct RouteListView: View {
    @Bindable var model: TravelScheduleModel

    var body: some View {
        VStack(spacing: 0) {
            TravelNavigationHeader()
            if let failure = model.routesFailure {
                FailureView(failure: failure)
            } else {
                Text(model.routeTitle)
                    .font(.system(size: 24, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                if model.isLoading {
                    ProgressView("Ищем варианты")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if model.filteredRoutes.isEmpty {
                    EmptyResultView(title: "Вариантов нет")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(model.filteredRoutes) { route in
                                NavigationLink {
                                    NamedPlaceholderView(title: "Информация о перевозчике", showsBack: true)
                                } label: {
                                    RouteRow(route: route)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.routesFailure == nil && !model.isLoading {
                NavigationLink {
                    TimeFilterView(model: model)
                } label: {
                    PrimaryActionLabel(title: "Уточнить время", hasIndicator: model.hasActiveFilters)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .background(TravelStyle.background)
            }
        }
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await model.loadRoutes() }
    }
}

private struct RouteRow: View {
    let route: TravelRoute

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                carrierLogo
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.carrier).font(.system(size: 17)).lineLimit(1)
                    if route.hasTransfers {
                        Text(route.transferTitle.map { "С пересадкой: \($0)" } ?? "С пересадкой")
                            .font(.system(size: 12))
                            .foregroundStyle(TravelStyle.red)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                Text(route.date)
                    .font(.system(size: 12))
                    .fixedSize()
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(height: 38)
            HStack(spacing: 5) {
                Text(route.departure).font(.system(size: 17))
                Rectangle().fill(TravelStyle.gray).frame(height: 1)
                Text(route.durationText).font(.system(size: 12)).fixedSize()
                Rectangle().fill(TravelStyle.gray).frame(height: 1)
                Text(route.arrival).font(.system(size: 17))
            }
        }
        .padding(14)
        .foregroundStyle(TravelStyle.black)
        .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var carrierLogo: some View {
        Group {
            if let logoName = route.carrierLogoName {
                Image(logoName).resizable().scaledToFit()
            } else {
                Image(systemName: "tram.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(TravelStyle.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white)
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}

private struct TimeFilterView: View {
    let model: TravelScheduleModel
    @Environment(\.dismiss) private var dismiss
    @State private var periods: Set<DeparturePeriod>
    @State private var transfers: Bool?

    init(model: TravelScheduleModel) {
        self.model = model
        _periods = State(initialValue: model.selectedPeriods)
        _transfers = State(initialValue: model.transferChoice)
    }

    var body: some View {
        VStack(spacing: 0) {
            TravelNavigationHeader()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Время отправления").font(.system(size: 24, weight: .bold))
                    VStack(spacing: 0) {
                        ForEach(DeparturePeriod.allCases) { period in
                            Button {
                                if periods.contains(period) { periods.remove(period) }
                                else { periods.insert(period) }
                            } label: {
                                optionRow(
                                    title: "\(period.rawValue) \(period.interval)",
                                    symbol: periods.contains(period) ? "checkmark.square.fill" : "square"
                                )
                            }
                            .accessibilityAddTraits(periods.contains(period) ? .isSelected : [])
                        }
                    }
                    Text("Показывать варианты с пересадками").font(.system(size: 24, weight: .bold))
                    VStack(spacing: 0) {
                        ForEach([true, false], id: \.self) { value in
                            Button { transfers = value } label: {
                                optionRow(
                                    title: value ? "Да" : "Нет",
                                    symbol: transfers == value ? "smallcircle.filled.circle" : "circle"
                                )
                            }
                            .accessibilityAddTraits(transfers == value ? .isSelected : [])
                        }
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !periods.isEmpty || transfers != nil || model.hasActiveFilters {
                Button {
                    model.selectedPeriods = periods
                    model.transferChoice = transfers
                    dismiss()
                } label: {
                    PrimaryActionLabel(title: "Применить")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .background(TravelStyle.background)
            }
        }
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func optionRow(title: String, symbol: String) -> some View {
        HStack {
            Text(title).font(.system(size: 17))
            Spacer()
            Image(systemName: symbol).font(.system(size: 24))
        }
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }
}

struct TravelNavigationHeader: View {
    var title = ""
    var onBack: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .overlay(alignment: .leading) {
                Button {
                    if let onBack { onBack() } else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Назад")
            }
            .foregroundStyle(TravelStyle.text)
    }
}

struct PrimaryActionLabel: View {
    let title: String
    var hasIndicator = false

    var body: some View {
        HStack(spacing: 4) {
            Text(title).font(.system(size: 17, weight: .bold))
            if hasIndicator { Circle().fill(TravelStyle.red).frame(width: 8, height: 8) }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(TravelStyle.blue, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct NamedPlaceholderView: View {
    let title: String
    var showsBack = false

    var body: some View {
        VStack(spacing: 0) {
            if showsBack { TravelNavigationHeader() }
            EmptyResultView(title: title)
        }
        .background(TravelStyle.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct EmptyResultView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 24, weight: .bold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
    }
}

struct FailureView: View {
    let failure: TravelFailure

    var body: some View {
        VStack(spacing: 16) {
            Image(failure.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 223, height: 223)
                .accessibilityHidden(true)
            Text(failure.title).font(.system(size: 24, weight: .bold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TravelStyle.background)
    }
}
