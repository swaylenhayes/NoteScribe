import SwiftUI

struct TranscriptionResultView: View {
    let transcription: Transcription
    private var textForSelectedTab: String {
        transcription.text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcription Result")
                .font(.headline)
            
            HStack {
                Spacer()
                AnimatedCopyButton(textToCopy: textForSelectedTab)
                AnimatedSaveButton(textToSave: textForSelectedTab)
            }
            
            ScrollView {
                Text(textForSelectedTab)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Text("Duration: \(formatDuration(transcription.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
}
