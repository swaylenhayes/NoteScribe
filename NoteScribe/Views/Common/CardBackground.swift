import SwiftUI

// Style Constants for consistent styling across components
struct StyleConstants {
    // Surface color adapts for light/dark so content never becomes white-on-white.
    static let surfaceFill = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(calibratedWhite: 0.22, alpha: 1.0)
        }
        return NSColor(calibratedWhite: 0.965, alpha: 1.0)
    })
    static let surfaceFillSelected = Color.accentColor.opacity(0.12)
    static let inputInsetFill = Color(NSColor.controlBackgroundColor)
    static let activeTabFill = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
    static let borderColor = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(calibratedWhite: 1.0, alpha: 0.16)
        }
        return NSColor.separatorColor.withAlphaComponent(0.45)
    })
    static let borderSelected = Color.accentColor.opacity(0.6)
    
    // Shadows
    static let shadowDefault = Color.black.opacity(0.06)
    static let shadowSelected = Color.black.opacity(0.10)
    
    static let cornerRadius: CGFloat = 16
}

struct NeutralControlButtonStyle: ButtonStyle {
    var fill: Color = StyleConstants.activeTabFill
    var cornerRadius: CGFloat = 8
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill.opacity(configuration.isPressed ? 0.82 : 1.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(StyleConstants.borderColor, lineWidth: 1)
            )
            .opacity(isEnabled ? 1.0 : 0.45)
    }
}

// Reusable background component
struct CardBackground: View {
    var isSelected: Bool
    var cornerRadius: CGFloat = StyleConstants.cornerRadius
    var useAccentGradientWhenSelected: Bool = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(isSelected ? StyleConstants.surfaceFillSelected : StyleConstants.surfaceFill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isSelected ? StyleConstants.borderSelected : StyleConstants.borderColor, lineWidth: 1)
            )
            .shadow(
                color: isSelected ? StyleConstants.shadowSelected : StyleConstants.shadowDefault,
                radius: isSelected ? 4 : 2,
                x: 0,
                y: 1
            )
    }
} 
