import SwiftUI

struct ContentView: View {
    @StateObject private var localWeather = LocalWeatherModel()
    @StateObject private var search = CitySearchModel()
    @State private var tab = WeatherTab.now
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width >= 620 && !typeSize.isAccessibilitySize {
                // Keep both models above the layout switch so resizing never resets a search.
                nativeNavigation {
                    HStack(alignment: .top, spacing: 0) {
                        currentLocationScreen
                            .frame(maxWidth: .infinity)
                        Divider()
                        citySearchScreen
                            .frame(maxWidth: .infinity)
                    }
                    .navigationTitle("Climance")
                }
            } else {
                TabView(selection: $tab) {
                    nativeNavigation {
                        currentLocationScreen.navigationTitle("Climance")
                    }
                    .tabItem { Label("Agora", systemImage: "location.fill") }
                    .tag(WeatherTab.now)
                    nativeNavigation {
                        citySearchScreen.navigationTitle("Buscar cidade")
                    }
                    .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
                    .tag(WeatherTab.search)
                }
            }
        }
        .tint(.blue)
        .task { localWeather.startIfNeeded() }
    }

    @ViewBuilder
    private func nativeNavigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
        }
    }

    private var currentLocationScreen: some View {
        WeatherPage {
            SectionHeading(eyebrow: "PERTO DE VOCÊ", title: "O tempo, agora.", subtitle: "A temperatura de onde você está.")
            if let reading = localWeather.reading {
                TemperatureCard(reading: reading, label: "Sua localização", symbol: "location.fill")
            } else {
                WeatherPlaceholder(symbol: "location.circle", title: "Seu dia começa aqui", message: "Permita sua localização para descobrir a temperatura ao seu redor.")
            }
            if localWeather.isLoading {
                LoadingStatus(text: "Consultando sua localização…")
            }
            if let message = localWeather.message {
                StatusMessage(text: message)
            }
            Button { localWeather.refresh() } label: {
                Label("Atualizar localização", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .disabled(localWeather.isLoading)
            attribution
        }
    }

    private var citySearchScreen: some View {
        WeatherPage {
            SectionHeading(eyebrow: "EXPLORE", title: "Como está por lá?", subtitle: "Consulte a temperatura atual de outra cidade.")
            VStack(alignment: .leading, spacing: 16) {
                Text("Qual cidade?").font(.headline)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Ex.: São Paulo", text: $search.query)
                        .textFieldStyle(.plain)
                        .onSubmit { search.search() }
                        .accessibilityLabel("Cidade")
                        .accessibilityIdentifier("cityInput")
                        .disabled(search.isLoading)
                        .cityKeyboard()
                }
                .padding(14)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                Button { search.search() } label: {
                    Text("Buscar cidade").frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!search.canSearch)
                .accessibilityIdentifier("searchButton")
            }
            .weatherPanel()

            if search.isLoading { LoadingStatus(text: "Consultando o tempo…") }
            if let message = search.message { StatusMessage(text: message) }
            if let reading = search.reading {
                TemperatureCard(reading: reading, label: "Cidade consultada", symbol: "mappin.and.ellipse")
                    .accessibilityIdentifier("temperatureResult")
            }
            if !search.cities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Escolha a cidade").font(.headline)
                    ForEach(search.cities) { city in
                        Button { search.select(city) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2).foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(city.name).font(.headline).foregroundColor(.primary)
                                    Text(city.region).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: search.selectedCityID == city.id ? "checkmark.circle.fill" : "chevron.right")
                                    .foregroundColor(.blue)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .disabled(search.isLoading)
                        .accessibilityLabel(city.displayName)
                    }
                }
                .weatherPanel()
            }
            if search.reading == nil && search.cities.isEmpty && !search.isLoading && search.message == nil {
                WeatherPlaceholder(symbol: "globe.americas", title: "Perto ou longe", message: "Busque uma cidade e escolha o local certo entre os resultados.")
            }
            attribution
        }
    }

    private var attribution: some View {
        HStack(spacing: 4) {
            Link("Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
            Text("·")
            Link("GeoNames", destination: URL(string: "https://www.geonames.org/")!)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

private enum WeatherTab: Hashable { case now, search }

private extension View {
    @ViewBuilder func cityKeyboard() -> some View {
        #if os(iOS)
        self.submitLabel(.search).autocorrectionDisabled().textInputAutocapitalization(.words)
        #else
        self
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
