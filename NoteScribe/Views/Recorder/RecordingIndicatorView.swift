import SwiftUI

private struct LeadingCapsuleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.height / 2, rect.width / 2)
        let topLeft = CGPoint(x: rect.minX + radius, y: rect.minY + radius)
        let bottomLeft = CGPoint(x: rect.minX + radius, y: rect.maxY - radius)

        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addArc(
            center: topLeft,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(180),
            clockwise: true
        )
        path.addArc(
            center: bottomLeft,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Floating status badge for live recording, warnings, and escape-cancel confirmation.
struct RecordingIndicatorView: View {
    @ObservedObject var transcriptionState: TranscriptionState
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var recordingStartDate = Date()
    @State private var isPulseActive = false
    @State private var pulseTask: Task<Void, Never>?

    private enum PillState: Equatable {
        case recording
        case noAudio
        case escPending
    }

    private var pillState: PillState {
        if transcriptionState.escPendingCancel {
            return .escPending
        }

        if transcriptionState.noAudioDetected {
            return .noAudio
        }

        return .recording
    }

    private var accentColor: Color {
        switch pillState {
        case .recording, .escPending:
            return Color(red: 0.89, green: 0.16, blue: 0.2)
        case .noAudio:
            return Color(red: 0.91, green: 0.58, blue: 0.14)
        }
    }

    private var bodyBackgroundColor: Color {
        Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.96)
    }

    private var recordingBadgeBaseColor: Color {
        Color(red: 0.08, green: 0.03, blue: 0.04)
    }

    private var fillOpacity: Double {
        switch pillState {
        case .recording:
            return 0
        case .noAudio:
            return 0.14
        case .escPending:
            return isPulseActive ? 0.94 : 0.16
        }
    }

    private var borderOpacity: Double {
        switch pillState {
        case .recording:
            return 0.78
        case .noAudio:
            return 0.82
        case .escPending:
            return isPulseActive ? 0.94 : 0.76
        }
    }

    private var glowOpacity: Double {
        switch pillState {
        case .recording:
            return isPulseActive ? 0.16 : 0.06
        case .noAudio:
            return 0.1
        case .escPending:
            return isPulseActive ? 0.32 : 0.1
        }
    }

    private var outerBorderColor: Color {
        Color.white
    }

    private var pillScale: CGFloat {
        switch pillState {
        case .recording:
            return 1.0
        case .noAudio:
            return 1.0
        case .escPending:
            return isPulseActive ? 1.016 : 1.0
        }
    }

    private var glowRadius: CGFloat {
        switch pillState {
        case .recording:
            return isPulseActive ? 8 : 5
        case .noAudio:
            return 6
        case .escPending:
            return isPulseActive ? 14 : 6
        }
    }

    private var recordingBadgeFillOpacity: Double {
        isPulseActive ? 0.98 : 0.14
    }

    private var recordingBadgeGlowOpacity: Double {
        isPulseActive ? 0.26 : 0.04
    }

    private var pulseDuration: Double {
        switch pillState {
        case .recording:
            return 1.0
        case .noAudio:
            return 0
        case .escPending:
            return 0.45
        }
    }

    private var labelText: String {
        switch pillState {
        case .recording:
            return "REC"
        case .noAudio:
            return "No audio detected"
        case .escPending:
            return "Press Esc again to cancel"
        }
    }

    private var symbolName: String {
        switch pillState {
        case .recording:
            return "record.circle.fill"
        case .noAudio:
            return "exclamationmark.triangle.fill"
        case .escPending:
            return "escape"
        }
    }

    private var timerText: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    private var timerReservationText: String {
        "00:00"
    }

    private var recordingContent: some View {
        HStack(spacing: 0) {
            ZStack {
                LeadingCapsuleShape()
                    .fill(recordingBadgeBaseColor)

                LeadingCapsuleShape()
                    .fill(accentColor.opacity(recordingBadgeFillOpacity))

                Text(labelText)
                    .font(.system(size: 11.5, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(0.5)
                    .shadow(color: Color.black.opacity(0.24), radius: 1, y: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(x: 3)
            }
            .frame(width: 53, height: 34, alignment: .center)

            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 1)

            ZStack(alignment: .trailing) {
                Text(timerReservationText)
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(.clear)

                Text(timerText)
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(height: 34)
            .padding(.leading, 9)
            .padding(.trailing, 8)
        }
    }

    private var statusContent: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: pillState == .escPending ? 10 : 11, weight: .bold))
                .foregroundStyle(accentColor)

            Text(labelText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            Text(timerText)
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.84))
                .frame(minWidth: 54, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    var body: some View {
        Group {
            if pillState == .recording {
                recordingContent
            } else {
                statusContent
            }
        }
        .background(
            Capsule()
                .fill(bodyBackgroundColor)
        )
        .overlay(
            Capsule()
                .fill(accentColor.opacity(fillOpacity))
        )
        .compositingGroup()
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(outerBorderColor, lineWidth: 1.5)
        )
        .scaleEffect(pillScale)
        .shadow(color: accentColor.opacity(glowOpacity), radius: glowRadius, y: 0)
        .shadow(color: Color.black.opacity(0.32), radius: 12, y: 5)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .fixedSize()
        .onAppear {
            if transcriptionState.recordingState == .recording {
                startTimer()
                updatePulseBehavior(startImmediately: true)
            }
        }
        .onDisappear {
            stopTimer()
            stopPulse()
        }
        .onChange(of: transcriptionState.recordingState) { _, newState in
            if newState == .recording {
                startTimer()
                updatePulseBehavior(startImmediately: true)
            } else {
                stopTimer()
                stopPulse()
            }
        }
        .onChange(of: pillState) { _, _ in
            updatePulseBehavior(startImmediately: true)
        }
    }

    private func startTimer() {
        stopTimer()
        elapsedSeconds = 0
        recordingStartDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                elapsedSeconds = Int(Date().timeIntervalSince(recordingStartDate))

                if pillState == .recording {
                    triggerRecordingPulseBeat()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func stopPulse() {
        pulseTask?.cancel()
        pulseTask = nil
        isPulseActive = false
    }

    private func updatePulseBehavior(startImmediately: Bool) {
        stopPulse()

        guard transcriptionState.recordingState == .recording else { return }

        switch pillState {
        case .recording:
            if startImmediately {
                triggerRecordingPulseBeat()
            }
        case .noAudio:
            isPulseActive = false
        case .escPending:
            startEscPendingPulse()
        }
    }

    private func triggerRecordingPulseBeat() {
        pulseTask?.cancel()
        pulseTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.14)) {
                isPulseActive = true
            }

            try? await Task.sleep(nanoseconds: UInt64((pulseDuration * 0.24) * 1_000_000_000))
            if Task.isCancelled { return }

            withAnimation(.easeInOut(duration: pulseDuration * 0.64)) {
                isPulseActive = false
            }
        }
    }

    private func startEscPendingPulse() {
        pulseTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPulseActive = true
                }

                try? await Task.sleep(nanoseconds: 160_000_000)
                if Task.isCancelled { return }

                withAnimation(.easeIn(duration: 0.18)) {
                    isPulseActive = false
                }

                try? await Task.sleep(nanoseconds: UInt64((pulseDuration * 0.58) * 1_000_000_000))
            }
        }
    }
}
