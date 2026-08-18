import SwiftUI
import WidgetKit

@main
struct KindlingWidgetBundle: WidgetBundle {
    var body: some Widget {
        SessionLiveActivity()
        SharedStoreProbeWidget()
    }
}
