import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct OruTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OruTimerAttributes.self) { context in
            // Pantalla de bloqueo y notificación expandida
            lockScreenView(context: context)
        // Configuración obligatoria Dynamic Island
        } dynamicIsland: { context in
            // Bloque de la vista expandida de la DI
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(
                        timerInterval: Date.now...context.state.endDate,
                        countsDown: true,
                        showsHours: false
                    )
                    .font(.title2.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.habitName ?? "Sesión de enfoque")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            // Vista compacta
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(
                    timerInterval: Date.now...context.state.endDate,
                    countsDown: true,
                    showsHours: false
                )
                .monospacedDigit()
                .frame(width: 40)
            // Vista minimal
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }

    private func lockScreenView(
        context: ActivityViewContext<OruTimerAttributes>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bird")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.habitName ?? "Sesión de enfoque")
                    .font(.headline)
                Text("¡Deja el móvil!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                timerInterval: Date.now...context.state.endDate,
                countsDown: true,
                showsHours: false
            )
            .font(.system(.title, design: .rounded).monospacedDigit())
            .contentTransition(.numericText())

            Button(intent: CancelTimerIntent()) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}
