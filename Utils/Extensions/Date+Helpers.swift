import Foundation

extension Date {
    func startOfMonth() -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }

    func endOfMonth() -> Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth())!
    }

    func isInCurrentMonth() -> Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    func formattedShort() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}
