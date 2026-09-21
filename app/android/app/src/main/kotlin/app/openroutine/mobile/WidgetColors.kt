package app.openroutine.mobile

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.widget.RemoteViews
import org.json.JSONObject

/** One scheme's worth of the colors the widget draws with, as ARGB ints. */
data class SchemeColors(
    val background: Int,
    val onSurface: Int,
    val onSurfaceVariant: Int,
    val accent: Int,
    val divider: Int,
) {
  companion object {
    fun parse(json: JSONObject?): SchemeColors? {
      if (json == null) return null
      val keys = listOf("background", "onSurface", "onSurfaceVariant", "accent", "divider")
      if (keys.any { !json.has(it) }) return null
      return SchemeColors(
          background = json.getLong("background").toInt(),
          onSurface = json.getLong("onSurface").toInt(),
          onSurfaceVariant = json.getLong("onSurfaceVariant").toInt(),
          accent = json.getLong("accent").toInt(),
          divider = json.getLong("divider").toInt(),
      )
    }
  }
}

/**
 * The palette chosen in Settings, in light and dark, and the theme mode that
 * picks between them. Written by `WidgetTheme` in
 * lib/services/home_widget/home_widget_publisher.dart.
 */
data class WidgetColors(val mode: String, val light: SchemeColors, val dark: SchemeColors) {

  /**
   * Calls [method] on [viewId] with the color [pick] chooses.
   *
   * When the app follows the system, Android 12 and later get both colors
   * and switch between them themselves, so the widget follows dark mode even
   * while the app is closed. Older versions get the one showing right now.
   */
  fun apply(
      context: Context,
      views: RemoteViews,
      viewId: Int,
      method: String,
      pick: (SchemeColors) -> Int,
  ) {
    when {
      mode == "light" -> views.setInt(viewId, method, pick(light))
      mode == "dark" -> views.setInt(viewId, method, pick(dark))
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
          views.setColorInt(viewId, method, pick(light), pick(dark))
      else -> views.setInt(viewId, method, pick(if (isNight(context)) dark else light))
    }
  }

  private fun isNight(context: Context): Boolean =
      context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
          Configuration.UI_MODE_NIGHT_YES

  companion object {
    /** Null when there's no theme, or it's malformed: the resources' colors stay. */
    fun parse(json: JSONObject?): WidgetColors? {
      if (json == null) return null
      val light = SchemeColors.parse(json.optJSONObject("light")) ?: return null
      val dark = SchemeColors.parse(json.optJSONObject("dark")) ?: return null
      return WidgetColors(json.optString("mode", "system"), light, dark)
    }
  }
}
