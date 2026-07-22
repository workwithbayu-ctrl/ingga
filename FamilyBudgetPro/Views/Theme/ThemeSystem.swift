import SwiftUI
import SwiftData
import Combine

// MARK: - Theme Enum
enum AppTheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case copilot = "Copilot Money"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .classic: return "square.grid.2x2"
        case .copilot: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Theme Manager (ObservableObject for iOS 16+)
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var selectedThemeRaw: String = AppTheme.classic.rawValue

    var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .classic
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: saved) {
            self.selectedThemeRaw = theme.rawValue
        }
    }

    func setTheme(_ theme: AppTheme) {
        selectedThemeRaw = theme.rawValue
    }
}

// MARK: - Theme Colors
struct ThemeColors {
    let primary: Color
    let secondary: Color
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let success: Color
    let danger: Color
    let warning: Color
    let shadow: Color
    let chartGradientStart: Color
    let chartGradientEnd: Color

    static let classic = ThemeColors(
        primary: .blue,
        secondary: .cyan,
        background: Color(.systemGroupedBackground),
        cardBackground: Color(.secondarySystemGroupedBackground),
        textPrimary: .primary,
        textSecondary: .secondary,
        success: .green,
        danger: .red,
        warning: .orange,
        shadow: .clear,
        chartGradientStart: .blue,
        chartGradientEnd: .cyan
    )

    static let copilot = ThemeColors(
        primary: Color(hex: "#1C1C1E") ?? .black,
        secondary: Color(hex: "#34C759") ?? .green,
        background: Color(hex: "#F2F2F7") ?? Color(.systemGroupedBackground),
        cardBackground: .white,
        textPrimary: Color(hex: "#1C1C1E") ?? .primary,
        textSecondary: Color(hex: "#8E8E93") ?? .secondary,
        success: Color(hex: "#34C759") ?? .green,
        danger: Color(hex: "#FF3B30") ?? .red,
        warning: Color(hex: "#FF9500") ?? .orange,
        shadow: Color.black.opacity(0.08),
        chartGradientStart: Color(hex: "#34C759") ?? .green,
        chartGradientEnd: Color(hex: "#30D158") ?? .green
    )
}

// MARK: - Theme Fonts
struct ThemeFonts {
    let largeTitle: Font
    let title: Font
    let headline: Font
    let body: Font
    let caption: Font
    let amount: Font
    let amountSmall: Font

    static let classic = ThemeFonts(
        largeTitle: .largeTitle.weight(.bold),
        title: .title2.weight(.bold),
        headline: .headline,
        body: .body,
        caption: .caption,
        amount: .system(size: 32, weight: .bold, design: .rounded),
        amountSmall: .system(size: 20, weight: .semibold, design: .rounded)
    )

    static let copilot = ThemeFonts(
        largeTitle: .system(size: 34, weight: .bold, design: .rounded),
        title: .system(size: 28, weight: .bold, design: .rounded),
        headline: .system(size: 17, weight: .semibold),
        body: .system(size: 16, weight: .regular),
        caption: .system(size: 13, weight: .medium),
        amount: .system(size: 36, weight: .bold, design: .rounded),
        amountSmall: .system(size: 22, weight: .semibold, design: .rounded)
    )
}

// MARK: - Theme Card Style
struct ThemeCardStyle {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowY: CGFloat
    let padding: CGFloat

    static let classic = ThemeCardStyle(
        cornerRadius: 16,
        shadowRadius: 0,
        shadowY: 0,
        padding: 16
    )

    static let copilot = ThemeCardStyle(
        cornerRadius: 20,
        shadowRadius: 8,
        shadowY: 4,
        padding: 20
    )
}

// MARK: - Theme Protocol
protocol ThemeProtocol {
    var colors: ThemeColors { get }
    var fonts: ThemeFonts { get }
    var cardStyle: ThemeCardStyle { get }
}

struct ClassicTheme: ThemeProtocol {
    let colors = ThemeColors.classic
    let fonts = ThemeFonts.classic
    let cardStyle = ThemeCardStyle.classic
}

struct CopilotTheme: ThemeProtocol {
    let colors = ThemeColors.copilot
    let fonts = ThemeFonts.copilot
    let cardStyle = ThemeCardStyle.copilot
}

// MARK: - Environment Key
struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeProtocol = ClassicTheme()
}

extension EnvironmentValues {
    var theme: ThemeProtocol {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier
struct ThemedViewModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        let theme: ThemeProtocol = themeManager.selectedTheme == .copilot ? CopilotTheme() : ClassicTheme()
        content
            .environment(\.theme, theme)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedViewModifier())
    }
}

// MARK: - Themed Card
struct ThemedCard<Content: View>: View {
    @Environment(\.theme) var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(theme.cardStyle.padding)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.cardStyle.cornerRadius)
            .shadow(
                color: theme.colors.shadow,
                radius: theme.cardStyle.shadowRadius,
                x: 0,
                y: theme.cardStyle.shadowY
            )
    }
}

// MARK: - Themed Transaction Row
struct ThemedTransactionRow: View {
    @Environment(\.theme) var theme
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: transaction.displayIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayTitle)
                    .font(theme.fonts.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.wallet?.name ?? "")
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(theme.colors.textSecondary)

                    Text(transaction.date, style: .date)
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount, format: .currency(code: "IDR"))
                    .font(theme.fonts.amountSmall)
                    .foregroundStyle(transaction.type == .income ? theme.colors.success : theme.colors.danger)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        Color(hex: transaction.displayColor) ?? .gray
    }
}

// MARK: - Themed Wallet Card
struct ThemedWalletCard: View {
    @Environment(\.theme) var theme
    let wallet: Wallet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: wallet.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(walletColor)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.colors.primary)
                    }
                }

                Text(wallet.name)
                    .font(theme.fonts.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)

                Text(wallet.balance, format: .currency(code: "IDR"))
                    .font(theme.fonts.amountSmall)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .padding(theme.cardStyle.padding)
            .frame(width: 160, height: 120)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.cardStyle.cornerRadius)
            .shadow(
                color: theme.colors.shadow,
                radius: theme.cardStyle.shadowRadius,
                x: 0,
                y: theme.cardStyle.shadowY
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardStyle.cornerRadius)
                    .stroke(isSelected ? theme.colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var walletColor: Color {
        Color(hex: wallet.colorHex) ?? .blue
    }
}

// MARK: - Themed Category Card
struct ThemedCategoryCard: View {
    @Environment(\.theme) var theme
    let category: Category
    let spent: Double
    let budget: Double

    var progress: Double {
        guard budget > 0 else { return 0 }
        return min(spent / budget, 1.0)
    }

    var isOverBudget: Bool {
        spent > budget && budget > 0
    }

    var body: some View {
        ThemedCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(categoryColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(category.name)
                            .font(theme.fonts.headline)
                            .foregroundStyle(theme.colors.textPrimary)

                        Spacer()

                        Text(spent, format: .currency(code: "IDR"))
                            .font(theme.fonts.body)
                            .foregroundStyle(isOverBudget ? theme.colors.danger : theme.colors.textPrimary)
                    }

                    if budget > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.colors.textSecondary.opacity(0.15))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isOverBudget ? theme.colors.danger : categoryColor)
                                    .frame(width: geo.size.width * progress, height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text("Budget: \(budget, format: .currency(code: "IDR"))")
                                .font(theme.fonts.caption)
                                .foregroundStyle(theme.colors.textSecondary)

                            Spacer()

                            if isOverBudget {
                                Text("Over Budget")
                                    .font(theme.fonts.caption)
                                    .foregroundStyle(theme.colors.danger)
                                    .fontWeight(.semibold)
                            } else {
                                Text("\((1 - progress) * 100, specifier: "%.0f")% left")
                                    .font(theme.fonts.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var categoryColor: Color {
        Color(hex: category.colorHex) ?? .gray
    }
}

// MARK: - Trend Indicator
struct TrendIndicator: View {
    @Environment(\.theme) var theme
    let value: Double
    let label: String

    var isPositive: Bool {
        value >= 0
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)

            Text("\(abs(value), specifier: "%.1f")%")
                .font(theme.fonts.caption)
        }
        .foregroundStyle(isPositive ? theme.colors.success : theme.colors.danger)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (isPositive ? theme.colors.success : theme.colors.danger)
                .opacity(0.1)
        )
        .cornerRadius(8)
    }
}
