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
                    Text(context.attributes.habitIcon ?? "📚")
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(
                        timerInterval: Date.now...max(context.state.endDate, Date.now + 1),
                        countsDown: true,
                        showsHours: false
                    )
                    .font(.title2.monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(width: 85)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.habitName ?? "Sesión de enfoque")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            // Vista compacta
            } compactLeading: {
                Text(context.attributes.habitIcon ?? "📚")
                    .font(.caption)
            } compactTrailing: {
                Text(
                    timerInterval: Date.now...max(context.state.endDate, Date.now + 1),
                    countsDown: true,
                    showsHours: false
                )
                .font(.caption.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
            // Vista minimal
            } minimal: {
                Text(context.attributes.habitIcon ?? "📚")
            }
        }
    }

    private func lockScreenView(
        context: ActivityViewContext<OruTimerAttributes>
    ) -> some View {
        HStack(spacing: 12) {
            Text(context.attributes.habitIcon ?? "📚")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.habitName ?? "Sesión de enfoque")
                    .font(.headline)
                Text("¡Deja el móvil!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            Spacer()

            Text(
                timerInterval: Date.now...max(context.state.endDate, Date.now + 1),
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
