package app.openroutine.mobile

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * The routine list as the app last published it.
 *
 * The widget never reads the database: `HomeWidgetPublisher` writes this
 * document whenever the routine list changes and the widget only renders it.
 * See lib/services/home_widget/home_widget_publisher.dart for the writer.
 */
data class RoutineSnapshot(
    val title: String,
    val empty: String,
    val routines: List<RoutineRow>,
) {
  companion object {
    /** Must match `HomeWidgetPublisher.dataKey`. */
    const val KEY = "routines_v1"

    /** Must match `HomeWidgetPublisher.payloadVersion`. */
    private const val VERSION = 1

    /**
     * Reads the snapshot, falling back to an empty one.
     *
     * Anything unexpected — no document yet because the app has never run, a
     * document written by a newer version, malformed JSON — renders the empty
     * state. A widget that throws is one the launcher shows as "Problem
     * loading widget" until it is removed and placed again.
     */
    fun read(context: Context, widgetData: SharedPreferences): RoutineSnapshot {
      val fallback =
          RoutineSnapshot(
              title = context.getString(R.string.widget_label),
              empty = context.getString(R.string.widget_empty_fallback),
              routines = emptyList(),
          )

      val raw = widgetData.getString(KEY, null) ?: return fallback

      return try {
        val document = JSONObject(raw)
        if (document.optInt("v") != VERSION) return fallback

        val strings = document.optJSONObject("strings")
        val routines = document.optJSONArray("routines")
        val rows = mutableListOf<RoutineRow>()
        for (index in 0 until (routines?.length() ?: 0)) {
          val routine = routines!!.optJSONObject(index) ?: continue
          val id = routine.optString("id").takeIf { it.isNotEmpty() } ?: continue
          rows.add(
              RoutineRow(
                  id = id,
                  name = routine.optString("name"),
                  startTime = routine.optString("startTime").takeIf { it.isNotEmpty() },
                  steps = routine.optString("steps"),
              )
          )
        }

        RoutineSnapshot(
            title = strings?.optString("title")?.takeIf { it.isNotEmpty() } ?: fallback.title,
            empty = strings?.optString("empty")?.takeIf { it.isNotEmpty() } ?: fallback.empty,
            routines = rows,
        )
      } catch (error: Exception) {
        fallback
      }
    }
  }
}

/**
 * One routine. `startTime` stays the schema's raw "HH:MM" so the widget can
 * format it against the phone's current 12/24-hour setting, and `steps` is
 * already localised and pluralised because only Dart has the plural rules.
 */
data class RoutineRow(
    val id: String,
    val name: String,
    val startTime: String?,
    val steps: String,
)
