import SwiftUI

struct DictionarySettingsView: View {
    // OFFLINE MODE: Removed "Correct Spellings" section (requires AI enhancement)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AppSectionHeader("Replacements") {
                    HStack(spacing: 12) {
                        Button(action: {
                            DictionaryImportExportService.shared.importDictionary()
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Import word replacements")

                        Button(action: {
                            DictionaryImportExportService.shared.exportDictionary()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Export word replacements")
                    }
                    .frame(height: 20)
                }

                WordReplacementView()
                    .padding(.horizontal, LayoutMetrics.horizontalInset)
                    .padding(.vertical, LayoutMetrics.horizontalInset)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
} 
