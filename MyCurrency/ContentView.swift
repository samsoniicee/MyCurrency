import SwiftUI

struct ContentView: View {
    @StateObject private var vm = CurrencyViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

            VStack(spacing: 10) {
                CurrencyRow(flag: "🇪🇺", code: "EUR", name: "Euro",       text: $vm.eur)
                CurrencyRow(flag: "🇺🇸", code: "USD", name: "US Dollar",  text: $vm.usd)
                CurrencyRow(flag: "🇦🇪", code: "AED", name: "UAE Dirham", text: $vm.aed)
            }
            .padding(.horizontal, 16)

            footer
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .task { await vm.fetchRates() }
    }

    // MARK: – Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text("MyCurrency")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("BETA")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
                }
                Text(vm.lastUpdatedLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 14) {
                Button { Task { await vm.fetchRates() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(vm.isLoading ? Color.accentColor : .secondary)
                        .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                        .animation(
                            vm.isLoading
                                ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                : .default,
                            value: vm.isLoading
                        )
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
                .help("Refresh EUR rate")

                Button { NSApplication.shared.terminate(nil) } label: {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit MyCurrency")
            }
        }
    }

    // MARK: – Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let err = vm.errorMessage {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange)
            } else {
                Text(vm.rateDescription)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            Text(versionString)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.quaternary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "MyCurrency by niicee  ·  v\(v)"
    }
}

// MARK: – CurrencyRow

struct CurrencyRow: View {
    let flag: String
    let code: String
    let name: String
    @Binding var text: String
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 14) {
            Text(flag)
                .font(.system(size: 30))
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(code)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(name)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            CurrencyTextField(text: $text, onFocusChange: { isFocused = $0 })
                .frame(width: 160, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isFocused ? Color.accentColor.opacity(0.5) : Color.clear,
                              lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isFocused
                  ? Color.accentColor.opacity(0.07)
                  : Color(NSColor.controlBackgroundColor))
    }
}
