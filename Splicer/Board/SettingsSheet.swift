import SwiftUI

/// Settings holds contact, a confirmed reset, and a way back through onboarding.
struct SettingsSheet: View {
    var reopen: () -> Void
    var reset: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        reopen()
                    } label: {
                        Text("Run onboarding again")
                            .spliceFace(.body)
                            .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6), alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
                Section {
                    Button {
                        confirmReset = true
                    } label: {
                        Text("Reset all data")
                            .spliceFace(.body)
                            .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6), alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ReleaseChromeStyle())
                } footer: {
                    Text("Reset removes the stack, the gate, and every burn on this device.")
                        .spliceFace(.caption)
                }
                Section {
                    if let contact = URL(string: "https://splicer-lane.pro/contact-us") {
                    Link(destination: contact) {
                        Text("Contact")
                            .spliceFace(.body)
                            .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6), alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignTokens.bg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .presentationBackground(DesignTokens.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(minWidth: SpliceTokens.space(6), minHeight: SpliceTokens.space(6))
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close settings")
                    .buttonStyle(InkPressStyle())
                }
            }
            .alert("Reset the board?", isPresented: $confirmReset) {
                Button("Reset all data", role: .destructive) { reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The stack, the gate, and every burn mark will leave this device.")
            }
        }
    }
}

/// Live cover for Settings.
struct SettingsView: View {
    var reopen: () -> Void
    var reset: () -> Void

    var body: some View {
        SettingsSheet(reopen: reopen, reset: reset)
    }
}
