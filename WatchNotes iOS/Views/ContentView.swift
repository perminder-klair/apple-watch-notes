import SwiftUI

/// iPhone companion app status dashboard
struct ContentView: View {
    @EnvironmentObject var connectivityService: WatchConnectivityService
    @ObservedObject var summarizationService = SummarizationService.shared

    var body: some View {
        NavigationStack {
            List {
                // AI Status Section
                Section {
                    HStack {
                        Image(systemName: summarizationService.isAvailable ? "brain" : "brain.fill")
                            .foregroundStyle(summarizationService.isAvailable ? .green : .orange)
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text("Apple Intelligence")
                                .font(.headline)
                            Text(summarizationService.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if summarizationService.isAvailable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("AI Status")
                }

                // Watch Connection Section
                Section {
                    StatusRow(
                        icon: "applewatch",
                        title: "Watch Paired",
                        isActive: connectivityService.isWatchPaired
                    )

                    StatusRow(
                        icon: "app.badge.checkmark",
                        title: "Watch App Installed",
                        isActive: connectivityService.isWatchAppInstalled
                    )

                    StatusRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Watch Reachable",
                        isActive: connectivityService.isWatchReachable
                    )
                } header: {
                    Text("Watch Connection")
                }

                // Activity Section
                Section {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundStyle(.blue)
                            .font(.title3)

                        VStack(alignment: .leading) {
                            Text("Pending Requests")
                                .font(.headline)

                            if connectivityService.pendingRequestCount > 0 {
                                Text("Processing \(connectivityService.pendingRequestCount) request(s)...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No active requests")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if connectivityService.pendingRequestCount > 0 {
                            ProgressView()
                        } else {
                            Text("\(connectivityService.pendingRequestCount)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if let lastRequest = connectivityService.lastSummarizationRequest {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)

                            Text("Last Request")
                                .font(.subheadline)

                            Spacer()

                            Text(lastRequest, style: .relative)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Activity")
                }

                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("This app runs in the background to generate AI summaries for your Watch notes.")
                        } icon: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)

                        Label {
                            Text("Keep this app installed for the summarization feature to work.")
                        } icon: {
                            Image(systemName: "iphone.and.arrow.forward")
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                } header: {
                    Text("How It Works")
                }
            }
            .navigationTitle("WatchNotes")
            .refreshable {
                summarizationService.checkAvailability()
                connectivityService.sendStatusUpdate()
            }
        }
    }
}

/// A reusable row for displaying status with icon
struct StatusRow: View {
    let icon: String
    let title: String
    let isActive: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isActive ? .green : .secondary)
                .font(.title3)

            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: isActive ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(isActive ? .green : .secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityService.shared)
}
