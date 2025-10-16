//
//  DesignSystem.swift
//  Musicon
//
//  Created by Claude on 10/15/25.
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary Colors
    static let primaryBlack = Color(red: 0.13, green: 0.13, blue: 0.13) // #212121
    static let accentGold = Color(red: 0.85, green: 0.65, blue: 0.13) // #D9A521

    // Background Colors
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let surfaceColor = Color(UIColor.tertiarySystemBackground)

    // Text Colors
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // Existing Colors (Keep for consistency)
    static let codeBlue = Color.blue
    static let tempoGreen = Color.green
    static let signatureOrange = Color.orange
}

// MARK: - Typography

extension Font {
    // Display
    static let displayLarge = Font.system(size: 34, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let displaySmall = Font.system(size: 24, weight: .semibold)

    // Title
    static let titleLarge = Font.system(size: 22, weight: .semibold)
    static let titleMedium = Font.system(size: 18, weight: .semibold)
    static let titleSmall = Font.system(size: 16, weight: .semibold)

    // Body
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // Label
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
}

// MARK: - Custom View Modifiers

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.accentGold)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct IconButtonStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .background(color.opacity(0.1))
            .clipShape(Circle())
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func iconButton(color: Color = .accentGold) -> some View {
        modifier(IconButtonStyle(color: color))
    }
}

// MARK: - Badge Style

struct BadgeStyle {
    let backgroundColor: Color
    let textColor: Color

    static let code = BadgeStyle(
        backgroundColor: Color.codeBlue.opacity(0.15),
        textColor: Color.codeBlue
    )

    static let tempo = BadgeStyle(
        backgroundColor: Color.tempoGreen.opacity(0.15),
        textColor: Color.tempoGreen
    )

    static let signature = BadgeStyle(
        backgroundColor: Color.signatureOrange.opacity(0.15),
        textColor: Color.signatureOrange
    )

    static let gold = BadgeStyle(
        backgroundColor: Color.accentGold.opacity(0.15),
        textColor: Color.accentGold
    )

    static let primary = BadgeStyle(
        backgroundColor: Color(UIColor.label).opacity(0.08),
        textColor: Color(UIColor.label)
    )
}

struct Badge: View {
    let text: String
    let style: BadgeStyle
    let icon: String?

    init(_ text: String, style: BadgeStyle = .primary, icon: String? = nil) {
        self.text = text
        self.style = style
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.labelMedium)
        }
        .foregroundStyle(style.textColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(style.backgroundColor)
        .clipShape(Capsule())
    }
}
