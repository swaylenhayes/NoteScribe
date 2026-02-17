import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TranscriptionHistoryView: View {
    let showsHeader: Bool
    let headerTitle: String
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var transcriptionState: TranscriptionState
    @State private var searchText = ""
    @State private var expandedTranscription: Transcription?
    @State private var selectedTranscriptions: Set<Transcription> = []
    @State private var showDeleteConfirmation = false
    @State private var isViewCurrentlyVisible = false
    @StateObject private var transcriptionManager = AudioTranscriptionManager.shared
    @State private var isDropTargeted = false
    
    private let exportService = NoteScribeCSVExportService()
    
    // Pagination states
    @State private var displayedTranscriptions: [Transcription] = []
    @State private var isLoading = false
    @State private var hasMoreContent = true
    
    // Cursor-based pagination - track the last timestamp
    @State private var lastTimestamp: Date?
    private let pageSize = 20
    
    @Query(Self.createLatestTranscriptionIndicatorDescriptor()) private var latestTranscriptionIndicator: [Transcription]

    init(showsHeader: Bool = true, headerTitle: String = "History") {
        self.showsHeader = showsHeader
        self.headerTitle = headerTitle
    }
    
    // Static function to create the FetchDescriptor for the latest transcription indicator
    private static func createLatestTranscriptionIndicatorDescriptor() -> FetchDescriptor<Transcription> {
        var descriptor = FetchDescriptor<Transcription>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return descriptor
    }
    
    // Cursor-based query descriptor
    private func cursorQueryDescriptor(after timestamp: Date? = nil) -> FetchDescriptor<Transcription> {
        var descriptor = FetchDescriptor<Transcription>(
            sortBy: [SortDescriptor(\Transcription.timestamp, order: .reverse)]
        )
        
        // Build the predicate based on search text and timestamp cursor
        if let timestamp = timestamp {
            if !searchText.isEmpty {
                descriptor.predicate = #Predicate<Transcription> { transcription in
                    (transcription.text.localizedStandardContains(searchText) ||
                    (transcription.enhancedText?.localizedStandardContains(searchText) ?? false)) &&
                    transcription.timestamp < timestamp
                }
            } else {
                descriptor.predicate = #Predicate<Transcription> { transcription in
                    transcription.timestamp < timestamp
                }
            }
        } else if !searchText.isEmpty {
            descriptor.predicate = #Predicate<Transcription> { transcription in
                transcription.text.localizedStandardContains(searchText) ||
                (transcription.enhancedText?.localizedStandardContains(searchText) ?? false)
            }
        }
        
        descriptor.fetchLimit = pageSize
        return descriptor
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if showsHeader {
                    transcriptionHeader
                }
                searchBar
                
                if displayedTranscriptions.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(displayedTranscriptions) { transcription in
                                    TranscriptionCard(
                                        transcription: transcription,
                                        isExpanded: expandedTranscription == transcription,
                                        isSelected: selectedTranscriptions.contains(transcription),
                                        onDelete: { deleteTranscription(transcription) },
                                        onToggleSelection: { toggleSelection(transcription) }
                                    )
                                    .id(transcription) // Using the object as its own ID
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            if expandedTranscription == transcription {
                                                expandedTranscription = nil
                                            } else {
                                                expandedTranscription = transcription
                                            }
                                        }
                                    }
                                }
                                
                                if hasMoreContent {
                                    Button(action: {
                                        Task {
                                            await loadMoreContent()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            if isLoading {
                                                ProgressView()
                                                    .controlSize(.small)
                                            }
                                            Text(isLoading ? "Loading..." : "Load More")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(CardBackground(isSelected: false))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isLoading)
                                    .padding(.top, 12)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: expandedTranscription)
                            .padding(LayoutMetrics.horizontalInset)
                            // Add bottom padding to ensure content is not hidden by the toolbar when visible
                            .padding(.bottom, !selectedTranscriptions.isEmpty ? 60 : 0)
                        }
                        .padding(.vertical, 16)
                        .onChange(of: expandedTranscription) { old, new in
                            if let transcription = new {
                                proxy.scrollTo(transcription, anchor: nil)
                            }
                        }
                    }
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            // Selection toolbar as an overlay
            if !selectedTranscriptions.isEmpty {
                selectionToolbar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: !selectedTranscriptions.isEmpty)
            }
        }
        .alert("Delete Selected Items?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelectedTranscriptions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. Are you sure you want to delete \(selectedTranscriptions.count) item\(selectedTranscriptions.count == 1 ? "" : "s")?")
        }
        .onAppear {
            isViewCurrentlyVisible = true
            Task {
                await loadInitialContent()
            }
        }
        .onDisappear {
            isViewCurrentlyVisible = false
        }
        .onChange(of: searchText) { _, _ in
            Task {
                resetPagination()
                await loadInitialContent()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileForTranscription)) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                startProcessingIfValidAudioFile(url)
            }
        }
        .onDrop(of: [.fileURL, .data, .audio, .movie], isTargeted: $isDropTargeted) { providers in
            if !transcriptionManager.isProcessing {
                handleDroppedFile(providers)
                return true
            }
            return false
        }
        // Improved change detection for new transcriptions
        .onChange(of: latestTranscriptionIndicator.first?.id) { oldId, newId in
            guard isViewCurrentlyVisible else { return } // Only proceed if the view is visible

            // Check if a new transcription was added or the latest one changed
            if newId != oldId {
                // Only refresh if we're on the first page (no pagination cursor set)
                // or if the view is active and new content is relevant.
                if lastTimestamp == nil {
                    Task {
                        resetPagination()
                        await loadInitialContent()
                    }
                } else {
                    // Reset pagination to show the latest content
                    Task {
                        resetPagination()
                        await loadInitialContent()
                    }
                }
            }
        }
    }

    private var transcriptionHeader: some View {
        AppSectionHeader(headerTitle) {
            HStack(spacing: 10) {
                Text(headerDropMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Button("Choose File") {
                    selectFileAndStartProcessing()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(transcriptionManager.isProcessing)
            }
        }
    }

    private var headerDropMessage: String {
        if transcriptionManager.isProcessing {
            return transcriptionManager.processingPhase.message
        }
        if isDropTargeted {
            return "Release to import file"
        }
        return "Drop audio or video files here or"
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search transcriptions", text: $searchText)
                .font(.system(size: 16, weight: .regular, design: .default))
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(12)
        .background(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: StyleConstants.cornerRadius)
                        .fill(StyleConstants.inputInsetFill)
                } else {
                    RoundedRectangle(cornerRadius: StyleConstants.cornerRadius)
                        .fill(StyleConstants.surfaceFill)
                }
            }
        )
        .overlay(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: StyleConstants.cornerRadius)
                        .stroke(StyleConstants.borderColor, lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: StyleConstants.cornerRadius)
                        .stroke(Color(NSColor.separatorColor).opacity(0.32), lineWidth: 1)
                }
            }
        )
        .padding(.horizontal, LayoutMetrics.horizontalInset)
        .padding(.top, LayoutMetrics.sectionGap)
        .padding(.bottom, 10)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No transcriptions found")
                .font(.system(size: 24, weight: .semibold, design: .default))
            Text("Your history will appear here")
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CardBackground(isSelected: false))
        .padding(LayoutMetrics.horizontalInset)
    }
    
    private var selectionToolbar: some View {
        HStack(spacing: 12) {
            Text("\(selectedTranscriptions.count) selected")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            Spacer()

            Button(action: {
                exportService.exportTranscriptionsToCSV(transcriptions: Array(selectedTranscriptions))
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
            }
            .buttonStyle(.borderless)
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
            }
            .buttonStyle(.borderless)
            
            if selectedTranscriptions.count < displayedTranscriptions.count {
                Button("Select All") {
                    Task {
                        await selectAllTranscriptions()
                    }
                }
                .buttonStyle(.borderless)
            } else {
                Button("Deselect All") {
                    selectedTranscriptions.removeAll()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            Color(.windowBackgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 3, y: -2)
        )
    }
    
    @MainActor
    private func loadInitialContent() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Reset cursor
            lastTimestamp = nil
            
            // Fetch initial page without a cursor
            let items = try modelContext.fetch(cursorQueryDescriptor())
            
            displayedTranscriptions = items
            // Update cursor to the timestamp of the last item
            lastTimestamp = items.last?.timestamp
            // If we got fewer items than the page size, there are no more items
            hasMoreContent = items.count == pageSize
        } catch {
            print("Error loading transcriptions: \(error)")
        }
    }
    
    @MainActor
    private func loadMoreContent() async {
        guard !isLoading, hasMoreContent, let lastTimestamp = lastTimestamp else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch next page using the cursor
            let newItems = try modelContext.fetch(cursorQueryDescriptor(after: lastTimestamp))
            
            // Append new items to the displayed list
            displayedTranscriptions.append(contentsOf: newItems)
            // Update cursor to the timestamp of the last new item
            self.lastTimestamp = newItems.last?.timestamp
            // If we got fewer items than the page size, there are no more items
            hasMoreContent = newItems.count == pageSize
        } catch {
            print("Error loading more transcriptions: \(error)")
        }
    }
    
    @MainActor
    private func resetPagination() {
        displayedTranscriptions = []
        lastTimestamp = nil
        hasMoreContent = true
        isLoading = false
    }
    
    private func deleteTranscription(_ transcription: Transcription) {
        // First delete the audio file if it exists
        if let urlString = transcription.audioFileURL,
           let url = URL(string: urlString) {
            try? FileManager.default.removeItem(at: url)
        }
        
        modelContext.delete(transcription)
        if expandedTranscription == transcription {
            expandedTranscription = nil
        }
        
        // Remove from selection if selected
        selectedTranscriptions.remove(transcription)
        
        // Refresh the view
        Task {
            try? modelContext.save()
            await loadInitialContent()
        }
    }
    
    private func deleteSelectedTranscriptions() {
        // Delete audio files and transcriptions
        for transcription in selectedTranscriptions {
            if let urlString = transcription.audioFileURL,
               let url = URL(string: urlString) {
                try? FileManager.default.removeItem(at: url)
            }
            modelContext.delete(transcription)
            if expandedTranscription == transcription {
                expandedTranscription = nil
            }
        }
        
        // Clear selection
        selectedTranscriptions.removeAll()
        
        // Save changes and refresh
        Task {
            try? modelContext.save()
            await loadInitialContent()
        }
    }
    
    private func toggleSelection(_ transcription: Transcription) {
        if selectedTranscriptions.contains(transcription) {
            selectedTranscriptions.remove(transcription)
        } else {
            selectedTranscriptions.insert(transcription)
        }
    }

    private func selectFileAndStartProcessing() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio, .movie]

        if panel.runModal() == .OK, let url = panel.url {
            startProcessingIfValidAudioFile(url)
        }
    }

    private func handleDroppedFile(_ providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        let typeIdentifiers = [
            UTType.fileURL.identifier,
            UTType.audio.identifier,
            UTType.movie.identifier,
            UTType.data.identifier,
            "public.file-url"
        ]

        for typeIdentifier in typeIdentifiers {
            if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                    if let error {
                        print("Error loading dropped file with type \(typeIdentifier): \(error)")
                        return
                    }

                    var fileURL: URL?
                    if let url = item as? URL {
                        fileURL = url
                    } else if let data = item as? Data {
                        if let url = URL(dataRepresentation: data, relativeTo: nil) {
                            fileURL = url
                        } else if let urlString = String(data: data, encoding: .utf8),
                                  let url = URL(string: urlString) {
                            fileURL = url
                        }
                    } else if let urlString = item as? String {
                        fileURL = URL(string: urlString)
                    }

                    if let finalURL = fileURL {
                        DispatchQueue.main.async {
                            self.startProcessingIfValidAudioFile(finalURL)
                        }
                    }
                }
                break
            }
        }
    }

    private func startProcessingIfValidAudioFile(_ url: URL) {
        guard !transcriptionManager.isProcessing else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        guard SupportedMedia.isSupported(url: url) else { return }
        transcriptionManager.startProcessing(
            url: url,
            modelContext: modelContext,
            transcriptionState: transcriptionState
        )
    }
    
    // Modified function to select all transcriptions in the database
    private func selectAllTranscriptions() async {
        do {
            // Create a descriptor without pagination limits to get all IDs
            var allDescriptor = FetchDescriptor<Transcription>()
            
            // Apply search filter if needed
            if !searchText.isEmpty {
                allDescriptor.predicate = #Predicate<Transcription> { transcription in
                    transcription.text.localizedStandardContains(searchText) ||
                    (transcription.enhancedText?.localizedStandardContains(searchText) ?? false)
                }
            }
            
            // For better performance, only fetch the IDs
            allDescriptor.propertiesToFetch = [\.id]
            
            // Fetch all matching transcriptions
            let allTranscriptions = try modelContext.fetch(allDescriptor)
            
            // Create a set of all visible transcriptions for quick lookup
            let visibleIds = Set(displayedTranscriptions.map { $0.id })
            
            // Add all transcriptions to the selection
            await MainActor.run {
                // First add all visible transcriptions directly
                selectedTranscriptions = Set(displayedTranscriptions)
                
                // Then add any non-visible transcriptions by ID
                for transcription in allTranscriptions {
                    if !visibleIds.contains(transcription.id) {
                        selectedTranscriptions.insert(transcription)
                    }
                }
            }
        } catch {
            print("Error selecting all transcriptions: \(error)")
        }
    }
}

struct CircularCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
    }
}
