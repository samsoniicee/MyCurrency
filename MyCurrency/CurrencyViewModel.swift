import Foundation

@MainActor
class CurrencyViewModel: ObservableObject {

    // didSet fires synchronously on every binding write.
    // `busy` prevents the other fields' didSet from re-triggering compute.
    @Published var eur = "" { didSet { guard !busy else { return }; compute("EUR", eur) } }
    @Published var usd = "" { didSet { guard !busy else { return }; compute("USD", usd) } }
    @Published var aed = "" { didSet { guard !busy else { return }; compute("AED", aed) } }

    @Published var rates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var busy = false


    // MARK: – Fetch

    func fetchRates() async {
        isLoading = true
        errorMessage = nil
        do {
            // Frankfurter = ECB data. AED is not ECB-tracked.
            // AED/USD is a fixed peg at 3.6725 set by the UAE Central Bank in 1997.
            let url = URL(string: "https://api.frankfurter.app/latest?from=USD&to=EUR")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let resp = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
            rates = [
                "USD": 1.0,
                "EUR": resp.rates["EUR"] ?? 0.9234,
                "AED": 3.6725
            ]
            lastUpdated = Date()
            recompute()
        } catch {
            errorMessage = "Could not fetch rates"
            if rates.isEmpty {
                rates = ["USD": 1.0, "EUR": 0.9234, "AED": 3.6725]
                recompute()
            }
        }
        isLoading = false
    }

    // MARK: – Conversion

    private func compute(_ currency: String, _ text: String) {
        // Strip thousands separators before parsing
        let clean = text
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !clean.isEmpty, let amount = Double(clean), !rates.isEmpty else {
            if clean.isEmpty {
                busy = true
                if currency != "EUR" { eur = "" }
                if currency != "USD" { usd = "" }
                if currency != "AED" { aed = "" }
                busy = false
            }
            return
        }

        guard let fromRate = rates[currency] else { return }
        let inUSD = amount / fromRate

        busy = true
        if currency != "EUR", let r = rates["EUR"] { eur = fmt(r * inUSD) }
        if currency != "USD", let r = rates["USD"] { usd = fmt(r * inUSD) }
        if currency != "AED", let r = rates["AED"] { aed = fmt(r * inUSD) }
        busy = false
    }

    private func recompute() {
        let stripped = { (s: String) in s.replacingOccurrences(of: ",", with: "") }
        if !eur.isEmpty, Double(stripped(eur)) != nil { compute("EUR", eur); return }
        if !usd.isEmpty, Double(stripped(usd)) != nil { compute("USD", usd); return }
        if !aed.isEmpty, Double(stripped(aed)) != nil { compute("AED", aed); return }
    }

    // MARK: – Helpers

    var rateDescription: String {
        guard let e = rates["EUR"] else { return "" }
        return String(format: "1 USD = %.4f EUR  ·  3.6725 AED (fixed)", e)
    }

    var lastUpdatedLabel: String {
        guard let d = lastUpdated else { return "Fetching rates…" }
        let f = DateFormatter(); f.timeStyle = .short
        return "Updated \(f.string(from: d))"
    }

    private func fmt(_ v: Double) -> String {
        CurrencyTextField.formatter.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
    }
}

private struct FrankfurterResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}
