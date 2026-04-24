import HeimdallAppUI
import SwiftUI

@main
struct HeimdallBarApp: App {
    @State private var model: AppModel

    @MainActor
    init() {
        self._model = State(initialValue: HeimdallBarAppCompositionRoot().appModel())
    }

    @MainActor
    var body: some Scene {
        HeimdallBarScenes(model: self.model)
    }
}
