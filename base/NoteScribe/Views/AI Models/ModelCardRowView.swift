import SwiftUI
import AppKit

struct ModelCardRowView: View {
    let model: any TranscriptionModel
    @ObservedObject var transcriptionState: TranscriptionState
    let isDownloaded: Bool
    let isCurrent: Bool
    let downloadProgress: [String: Double]
    let modelURL: URL?
    let isWarming: Bool
    
    // Actions (OFFLINE MODE: No edit action for custom models)
    var deleteAction: () -> Void
    var setDefaultAction: () -> Void
    var downloadAction: () -> Void
    var body: some View {
        Group {
            if let parakeetModel = model as? ParakeetModel {
                ParakeetModelCardRowView(
                    model: parakeetModel,
                    transcriptionState: transcriptionState
                )
            }
        }
    }
}
