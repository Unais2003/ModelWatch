import SwiftUI

struct PrivacyOnboardingView: View {
    @Environment(\.openSettings) private var openSettings

    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to ModelWatch")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Activity monitoring is private, local, and off by default.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                PrivacyOnboardingRow(
                    icon: "checkmark.shield",
                    title: "You choose the applications",
                    detail: "Only applications you explicitly approve can create usage sessions."
                )
                PrivacyOnboardingRow(
                    icon: "internaldrive",
                    title: "Activity stays on this Mac",
                    detail: "ModelWatch stores application identity and session start and end times locally."
                )
                PrivacyOnboardingRow(
                    icon: "hand.raised",
                    title: "No content access",
                    detail: "ModelWatch does not read windows, keystrokes, prompts, files, or screen content."
                )
            }

            HStack {
                Button("Not Now") {
                    onComplete()
                }

                Spacer()

                Button("Choose Applications…") {
                    onComplete()
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 560)
        .interactiveDismissDisabled()
    }
}

private struct PrivacyOnboardingRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
