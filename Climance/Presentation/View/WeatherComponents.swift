import SwiftUI

struct WeatherPage<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            pageContent
        }
        .background(
            LinearGradient(colors: colorScheme == .dark
                ? [Color(red: 0.05, green: 0.09, blue: 0.16), Color(red: 0.08, green: 0.13, blue: 0.21)]
                : [Color(red: 0.94, green: 0.97, blue: 1), Color(red: 0.98, green: 0.99, blue: 1)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var pageContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer(spacing: 24) { pageStack }
        } else {
            pageStack
        }
    }

    private var pageStack: some View {
        VStack(alignment: .leading, spacing: 24, content: content)
            .padding(20)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
    }

}

struct SectionHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow).font(.caption.weight(.semibold)).tracking(2).foregroundColor(.secondary)
            Text(title).font(.largeTitle.weight(.bold)).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
}

struct TemperatureCard: View {
    let reading: WeatherReading
    let label: String
    let symbol: String
    @AppStorage("usesFahrenheit") private var usesFahrenheit = false
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize = 84

    private var temperature: String {
        let value = usesFahrenheit ? reading.temperature * 9 / 5 + 32 : reading.temperature
        return value.formatted(.number.locale(Locale(identifier: "pt_BR")).precision(.fractionLength(1)))
    }

    private var unitName: String { usesFahrenheit ? "Fahrenheit" : "Celsius" }
    private var nextUnitName: String { usesFahrenheit ? "Celsius" : "Fahrenheit" }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(label, systemImage: symbol)
                .font(.subheadline.weight(.medium))
            Text(reading.location)
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text("\(temperature)°")
                .font(.system(size: temperatureSize, weight: .light, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityLabel("\(temperature) graus \(unitName)")
            Button { usesFahrenheit.toggle() } label: {
                HStack(spacing: 8) {
                    Text("Temperatura atual · \(unitName)")
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unidade de temperatura: \(unitName)")
            .accessibilityHint("Toque para mudar para \(nextUnitName)")
            .accessibilityIdentifier("temperatureUnitButton")
            Divider().accessibilityHidden(true)
            Label("Consultado às \(reading.updatedAt.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                .font(.caption)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .weatherGlassSurface(cornerRadius: 28, emphasized: true)
        .accessibilityElement(children: .contain)
    }
}

struct WeatherPlaceholder: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: symbol).font(.system(size: 40, weight: .light)).foregroundColor(.blue).accessibilityHidden(true)
            Text(title).font(.title2.weight(.semibold))
            Text(message).font(.subheadline).foregroundColor(.secondary)
        }
        .weatherPanel()
    }
}

struct LoadingStatus: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct StatusMessage: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "info.circle")
            .font(.subheadline)
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .weatherPanel()
    }
}

extension View {
    func weatherPanel() -> some View {
        self.padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .weatherGlassSurface(cornerRadius: 22)
    }

    @ViewBuilder
    func weatherGlassSurface(cornerRadius: CGFloat, emphasized: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, macOS 26.0, *) {
            if emphasized {
                self.foregroundStyle(.primary)
                    .glassEffect(.regular.tint(.blue.opacity(0.2)), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else if emphasized {
            self.foregroundColor(.white)
                .background(
                    LinearGradient(colors: [Color(red: 0.06, green: 0.29, blue: 0.58), Color(red: 0.08, green: 0.40, blue: 0.57)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: shape
                )
                .overlay(shape.stroke(Color.white.opacity(0.12), lineWidth: 1))
        } else {
            self.background(.regularMaterial, in: shape)
                .overlay(shape.stroke(Color.primary.opacity(0.05), lineWidth: 1))
        }
    }
}

struct TemperatureCard_Previews: PreviewProvider {
    static var previews: some View {
        WeatherPage {
            SectionHeading(eyebrow: "PERTO DE VOCÊ", title: "O tempo, agora.", subtitle: "A temperatura de onde você está.")
            TemperatureCard(reading: WeatherReading(location: "São Paulo, Brasil", temperature: 23.4), label: "Sua localização", symbol: "location.fill")
        }
    }
}
