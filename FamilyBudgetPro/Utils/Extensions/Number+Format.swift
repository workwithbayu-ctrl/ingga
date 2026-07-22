import Foundation

extension Double {
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "Rp0"
    }
}

extension Int {
    func formattedCurrency() -> String {
        Double(self).formattedCurrency()
    }
}
