import SwiftUI

struct ModelSettingsView: View {
    @ObservedObject var transcriptionPrompt: TranscriptionPrompt
    @AppStorage("SelectedLanguage") private var selectedLanguage: String = "en"
    @AppStorage("IsTextFormattingEnabled") private var isTextFormattingEnabled = true
    @AppStorage("IsVADEnabledLive") private var isVADEnabledLive = true
    @AppStorage("IsVADEnabledFile") private var isVADEnabledFile = true
    @AppStorage("AppendTrailingSpace") private var appendTrailingSpace = true
    @State private var customPrompt: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Output Format")
                    .font(.headline)
                
                InfoTip(
                    title: "Output Format Guide",
                    message: "Unlike GPT, Voice Models follows the style of your prompt rather than instructions. Use examples of your desired output format instead of commands.",
                    learnMoreURL: "https://cookbook.[removed]#comparison-with-gpt-prompting"
                )
                
                Spacer()
                
                Button(action: {
                    if isEditing {
                        // Save changes
                        transcriptionPrompt.setCustomPrompt(customPrompt, for: selectedLanguage)
                        isEditing = false
                    } else {
                        // Enter edit mode
                        customPrompt = transcriptionPrompt.getLanguagePrompt(for: selectedLanguage)
                        isEditing = true
                    }
                }) {
                    Text(isEditing ? "Save" : "Edit")
                        .font(.caption)
                }
            }
            
            if isEditing {
                TextEditor(text: $customPrompt)
                    .font(.system(size: 12))
                    .padding(8)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
            } else {
                Text(transcriptionPrompt.getLanguagePrompt(for: selectedLanguage))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.windowBackgroundColor).opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }

            Divider().padding(.vertical, 4)

            HStack {
                Toggle(isOn: $appendTrailingSpace) {
                    Text("Add space after paste")
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "Trailing Space",
                    message: "Automatically add a space after pasted text. Useful for space-delimited languages."
                )
            }

            HStack {
                Toggle(isOn: $isTextFormattingEnabled) {
                    Text("Automatic text formatting")
                }
                .toggleStyle(.switch)
                
                InfoTip(
                    title: "Automatic Text Formatting",
                    message: "Apply intelligent text formatting to break large block of text into paragraphs."
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Toggle(isOn: $isVADEnabledLive) {
                        Text("Use VAD for live dictation (hotkey/mini recorder)")
                    }
                    .toggleStyle(.switch)
                    
                    InfoTip(
                        title: "Live dictation VAD",
                        message: "Detect speech and skip silence during hotkey/minirecorder use. Can add overhead on short, clean dictation."
                    )
                }

                HStack {
                    Toggle(isOn: $isVADEnabledFile) {
                        Text("Use VAD for file transcription")
                    }
                    .toggleStyle(.switch)
                    
                    InfoTip(
                        title: "File transcription VAD",
                        message: "Detect speech and skip silence when importing files. Can add overhead on short/clean clips."
                    )
                }
            }

        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        // Reset the editor when language changes
        .onChange(of: selectedLanguage) { oldValue, newValue in
            if isEditing {
                customPrompt = transcriptionPrompt.getLanguagePrompt(for: selectedLanguage)
            }
        }
    }
} 
