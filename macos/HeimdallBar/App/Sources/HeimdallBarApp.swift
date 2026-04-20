import AppKit
import HeimdallBarShared
import Observation
import SwiftUI

@main
struct HeimdallBarApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(self.model.config.mergeIcons)) {
            RootMenuView(model: self.model)
                .task { self.model.start() }
        } label: {
            MenuBarLabel(
                title: "Heimdall",
                image: MenuBarMeterRenderer.image(
                    primary: self.model.visibleProviders.compactMap { self.model.snapshot(for: $0)?.primary }.first,
                    secondary: self.model.visibleProviders.compactMap { self.model.snapshot(for: $0)?.secondary }.first,
                    stale: self.model.snapshots.first?.stale ?? false
                )
            )
        }

        MenuBarExtra(isInserted: .constant(!self.model.config.mergeIcons && self.model.config.claude.enabled)) {
            ProviderMenuView(model: self.model, provider: .claude)
                .task { self.model.start() }
        } label: {
            MenuBarLabel(
                title: self.model.menuTitle(for: .claude),
                image: MenuBarMeterRenderer.image(
                    primary: self.model.snapshot(for: .claude)?.primary,
                    secondary: self.model.snapshot(for: .claude)?.secondary,
                    stale: self.model.snapshot(for: .claude)?.stale ?? false
                )
            )
        }

        MenuBarExtra(isInserted: .constant(!self.model.config.mergeIcons && self.model.config.codex.enabled)) {
            ProviderMenuView(model: self.model, provider: .codex)
                .task { self.model.start() }
        } label: {
            MenuBarLabel(
                title: self.model.menuTitle(for: .codex),
                image: MenuBarMeterRenderer.image(
                    primary: self.model.snapshot(for: .codex)?.primary,
                    secondary: self.model.snapshot(for: .codex)?.secondary,
                    stale: self.model.snapshot(for: .codex)?.stale ?? false
                )
            )
        }

        Settings {
            SettingsView(model: self.model)
                .frame(width: 480, height: 360)
        }
    }
}

struct MenuBarLabel: View {
    let title: String
    let image: NSImage

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: self.image)
            Text(self.title)
        }
    }
}
