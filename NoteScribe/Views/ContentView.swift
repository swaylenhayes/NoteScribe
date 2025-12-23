import SwiftUI
import SwiftData
import KeyboardShortcuts

// OFFLINE MODE: Detect offline mode
#if !ENABLE_AI_ENHANCEMENT
private let isOfflineMode = true
#else
private let isOfflineMode = false
#endif

enum TabDestination: String, CaseIterable, Identifiable {
    case scratchpad = "NoteScribe"
    case transcription = "File Transcription"
    case history = "History"
    case replacements = "Replacements"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scratchpad: return "square.and.pencil"
        case .transcription: return "waveform.circle.fill"
        case .history: return "doc.text.fill"
        case .replacements: return "character.book.closed.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

/// Full-screen overlay shown while the AI model is loading at startup
struct ModelLoadingOverlay: View {
    @State private var animationPhase = 0.0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated brain/AI icon
                Image(systemName: "brain")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)

                VStack(spacing: 12) {
                    Text("Loading AI Model")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Preparing for instant transcription...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }

                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .tint(.white)
                    .padding(.top, 8)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var transcriptionState: TranscriptionState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @AppStorage("powerModeUIFlag") private var powerModeUIFlag = false
    @State private var selectedTab: TabDestination = .scratchpad
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ScratchpadView()
                    .tabItem {
                        Label("NoteScribe", systemImage: TabDestination.scratchpad.icon)
                    }
                    .tag(TabDestination.scratchpad)

                AudioTranscribeView()
                    .tabItem {
                        Label("File Transcription", systemImage: TabDestination.transcription.icon)
                    }
                    .tag(TabDestination.transcription)

                TranscriptionHistoryView()
                    .tabItem {
                        Label("History", systemImage: TabDestination.history.icon)
                    }
                    .tag(TabDestination.history)

                DictionarySettingsView()
                    .tabItem {
                        Label("Replacements", systemImage: TabDestination.replacements.icon)
                    }
                    .tag(TabDestination.replacements)

                SettingsView()
                    .environmentObject(transcriptionState)
                    .tabItem {
                        Label("Settings", systemImage: TabDestination.settings.icon)
                    }
                    .tag(TabDestination.settings)
            }

            // Model loading overlay - shown during initial warmup
            if transcriptionState.isModelLoading {
                ModelLoadingOverlay()
            }
        }
        .frame(minWidth: 940, minHeight: 730)
        // OFFLINE MODE: Removed NoteScribe Pro, Enhancement, Power Mode destinations
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                switch destination {
                case "NoteScribe", "Home":
                    selectedTab = .scratchpad
                case "Settings":
                    selectedTab = .settings
                case "Transcription", "Transcribe Audio":
                    selectedTab = .transcription
                case "History":
                    selectedTab = .history
                case "Replacements":
                    selectedTab = .replacements
                default:
                    break
                }
            }
        }
    }
}
