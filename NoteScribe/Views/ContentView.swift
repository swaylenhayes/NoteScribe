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
    case scratchpad = "Scratch Pad"
    case transcription = "Transcription"
    case replacements = "Replacements"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .scratchpad: return "square.and.pencil"
        case .transcription: return "waveform.circle.fill"
        case .replacements: return "character.book.closed.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

enum LayoutMetrics {
    static let horizontalInset: CGFloat = 24
    static let sectionHeaderTop: CGFloat = 16
    static let sectionHeaderBottom: CGFloat = 12
    static let sectionHeaderRowHeight: CGFloat = 34
    static let sectionGap: CGFloat = 16
}

struct AppSectionHeader<Accessory: View>: View {
    private let title: String
    private let accessory: Accessory

    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                accessory
            }
            .frame(height: LayoutMetrics.sectionHeaderRowHeight, alignment: .center)
            .padding(.horizontal, LayoutMetrics.horizontalInset)
            .padding(.top, LayoutMetrics.sectionHeaderTop)
            .padding(.bottom, LayoutMetrics.sectionHeaderBottom)

            Divider()
                .padding(.horizontal, LayoutMetrics.horizontalInset)
        }
    }
}

extension AppSectionHeader where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

struct TranscriptionWorkspaceView: View {
    var body: some View {
        TranscriptionHistoryView(showsHeader: true, headerTitle: "Transcription")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
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
                    .foregroundColor(.white)
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
                        Label(TabDestination.scratchpad.rawValue, systemImage: TabDestination.scratchpad.icon)
                    }
                    .tag(TabDestination.scratchpad)

                TranscriptionWorkspaceView()
                    .tabItem {
                        Label(TabDestination.transcription.rawValue, systemImage: TabDestination.transcription.icon)
                    }
                    .tag(TabDestination.transcription)

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
        .frame(minWidth: 650, minHeight: 730)
        // OFFLINE MODE: Removed NoteScribe Pro, Enhancement, Power Mode destinations
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDestination)) { notification in
            if let destination = notification.userInfo?["destination"] as? String {
                switch destination {
                case "NoteScribe", "Scratch Pad", "Scratchpad", "Home":
                    selectedTab = .scratchpad
                case "Settings":
                    selectedTab = .settings
                case "Transcription", "File Transcription", "Transcribe Audio", "History":
                    selectedTab = .transcription
                case "Replacements":
                    selectedTab = .replacements
                default:
                    break
                }
            }
        }
    }
}
