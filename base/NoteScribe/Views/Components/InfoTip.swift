import SwiftUI

/// A reusable info tip component that displays helpful information in a popover
struct InfoTip: View {
    // Content configuration
    var title: String
    var message: String
    
    // Appearance customization
    var iconName: String = "info.circle.fill"
    var iconSize: Image.Scale = .medium
    var iconColor: Color = .primary
    var width: CGFloat = 300
    
    // State
    @State private var isShowingTip: Bool = false
    
    var body: some View {
        Image(systemName: iconName)
            .imageScale(iconSize)
            .foregroundColor(iconColor)
            .fontWeight(.semibold)
            .padding(5)
            .contentShape(Rectangle())
            .popover(isPresented: $isShowingTip) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: width, alignment: .leading)
                    
                }
                .padding(16)
            }
            .onTapGesture {
                isShowingTip.toggle()
            }
    }
}

    // MARK: - Convenience initializers

extension InfoTip {
    /// Creates an InfoTip with just title and message
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}
