import SwiftUI

struct ScratchpadView: View {
    @AppStorage("ScratchpadText") private var scratchpadText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scratchpad")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(scratchpadText.count) chars")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Clear") {
                    scratchpadText = ""
                }
                .buttonStyle(.bordered)
                .disabled(scratchpadText.isEmpty)
            }

            TextEditor(text: $scratchpadText)
                .font(.body)
                .placeholder(when: scratchpadText.isEmpty) {
                    Text("Type or paste text here…").foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
