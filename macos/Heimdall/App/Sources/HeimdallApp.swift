import HeimdallAppUI
import SwiftUI

@main
struct HeimdallApp: App {
    @State private var model: AppModel

    @MainActor
    init() {
        self._model = State(initialValue: HeimdallAppCompositionRoot().appModel())
    }

    @MainActor
    var body: some Scene {
        HeimdallScenes(model: self.model)
    }
}
