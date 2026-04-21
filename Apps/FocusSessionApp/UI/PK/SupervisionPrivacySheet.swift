import SwiftUI

struct SupervisionPrivacySheet: View {
    @Binding var isPresented: Bool
    let eligibility: SupervisionEligibility

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Supervision Privacy")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppSurfaceTheme.primaryText)
                Spacer()
                Button("Done") { isPresented = false }
                    .buttonStyle(.borderless)
            }

            Text("TodayFocus uses your camera and screen to verify presence and focus during PK sessions. Data is processed on-device and only violation snapshots are shared with your room.")
                .font(.body)
                .foregroundStyle(AppSurfaceTheme.secondaryText)

            if case .ineligible(let reasons) = eligibility {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Action Required")
                        .font(.headline)
                        .foregroundStyle(AppSurfaceTheme.primaryText)

                    ForEach(Array(reasons.enumerated()), id: \.offset) { _, reason in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color(red: 1.0, green: 0.50, blue: 0.52))
                            Text(reason.localizedDescription)
                                .font(.callout)
                                .foregroundStyle(AppSurfaceTheme.primaryText)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(28)
        .frame(minWidth: 480, minHeight: 320)
        .background(AppCanvasBackground())
    }
}

extension SupervisionEligibility.IneligibilityReason {
    var localizedDescription: String {
        switch self {
        case .notSignedIn:
            return "Sign in to enable supervision."
        case .cameraPermissionDenied:
            return "Camera access is required. Grant permission in System Settings."
        case .screenRecordingPermissionDenied:
            return "Screen recording access is required. Grant permission in System Settings."
        }
    }
}
