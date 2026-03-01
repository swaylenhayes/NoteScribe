import AppKit
import Combine
import QuartzCore
import SwiftUI

/// Floating panel that shows a recording status pill near the top-center of the primary display.
/// Non-activating: never steals focus from the user's active app.
final class RecordingIndicatorPanel: NSPanel {
    private let indicatorHostingView: NSHostingView<RecordingIndicatorView>
    private var cancellables = Set<AnyCancellable>()

    init(transcriptionState: TranscriptionState) {
        indicatorHostingView = NSHostingView(rootView: RecordingIndicatorView(transcriptionState: transcriptionState))

        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        contentView = indicatorHostingView
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        hasShadow = false
        backgroundColor = .clear
        isOpaque = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow

        observeIndicatorState(transcriptionState)
    }

    func positionOnPrimaryDisplay() {
        guard let screen = NSScreen.screens.first ?? NSScreen.main else { return }

        let idealSize = indicatorHostingView.fittingSize
        setContentSize(idealSize)

        let x = screen.frame.midX - (idealSize.width / 2)
        let y = screen.visibleFrame.maxY - 15 - idealSize.height

        setFrameOrigin(NSPoint(x: x, y: y))
    }

    func showIndicator() {
        positionOnPrimaryDisplay()
        alphaValue = 0
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }
    }

    func hideIndicator(animated: Bool = false, completion: (() -> Void)? = nil) {
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                self?.orderOut(nil)
                completion?()
            })
        } else {
            alphaValue = 0
            orderOut(nil)
            completion?()
        }
    }

    private func observeIndicatorState(_ transcriptionState: TranscriptionState) {
        transcriptionState.$noAudioDetected
            .combineLatest(transcriptionState.$escPendingCancel, transcriptionState.$isMiniRecorderVisible)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, isVisible in
                guard let self, isVisible, self.isVisible else { return }
                DispatchQueue.main.async {
                    self.positionOnPrimaryDisplay()
                }
            }
            .store(in: &cancellables)
    }
}
