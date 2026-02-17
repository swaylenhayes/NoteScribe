import SwiftUI

struct ScratchpadView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("ScratchpadText") private var scratchpadText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AppSectionHeader("Scratch Pad") {
                HStack(spacing: 10) {
                    Text("\(scratchpadText.count) chars")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    if colorScheme == .dark {
                        Button("Clear") {
                            scratchpadText = ""
                        }
                        .buttonStyle(NeutralControlButtonStyle())
                        .disabled(scratchpadText.isEmpty)
                    } else {
                        Button("Clear") {
                            scratchpadText = ""
                        }
                        .buttonStyle(.bordered)
                        .disabled(scratchpadText.isEmpty)
                    }
                }
            }

            TextEditor(text: $scratchpadText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .placeholder(when: scratchpadText.isEmpty) {
                    Text("Type or paste text here…").foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Group {
                        if colorScheme == .dark {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(StyleConstants.inputInsetFill)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(StyleConstants.surfaceFill)
                        }
                    }
                )
                .overlay(
                    Group {
                        if colorScheme == .dark {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(StyleConstants.borderColor, lineWidth: 1)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(NSColor.separatorColor).opacity(0.35), lineWidth: 1)
                        }
                    }
                )
                .padding(.horizontal, LayoutMetrics.horizontalInset)
                .padding(.vertical, LayoutMetrics.sectionGap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
