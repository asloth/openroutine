package app.openroutine.mobile

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.text.format.DateFormat
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

/** Feeds the widget's list. One factory per placed widget. */
class RoutineListService : RemoteViewsService() {
  override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
      RoutineListFactory(applicationContext)
}

class RoutineListFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

  private var rows: List<RoutineRow> = emptyList()
  private var colors: WidgetColors? = null

  override fun onCreate() = Unit

  /** Called on every `notifyAppWidgetViewDataChanged`, which is every publish. */
  override fun onDataSetChanged() {
    val snapshot = RoutineSnapshot.read(context, HomeWidgetPlugin.getData(context))
    rows = snapshot.routines
    colors = snapshot.colors
  }

  override fun onDestroy() {
    rows = emptyList()
  }

  override fun getCount() = rows.size

  override fun getViewAt(position: Int): RemoteViews {
    val row = rows[position]
    return RemoteViews(context.packageName, R.layout.routine_widget_row).apply {
      setTextViewText(R.id.row_time, formatStartTime(row.startTime))
      setTextViewText(R.id.row_name, row.name)
      setTextViewText(R.id.row_steps, row.steps)
      // The divider sits under each row rather than on the ListView, which
      // can't be recolored remotely.
      setViewVisibility(
          R.id.row_divider,
          if (position == rows.lastIndex) android.view.View.GONE else android.view.View.VISIBLE,
      )
      colors?.let { colors ->
        colors.apply(context, this, R.id.row_time, "setTextColor") { it.accent }
        colors.apply(context, this, R.id.row_name, "setTextColor") { it.onSurface }
        colors.apply(context, this, R.id.row_steps, "setTextColor") { it.onSurfaceVariant }
        colors.apply(context, this, R.id.row_divider, "setBackgroundColor") { it.divider }
      }
      // Only the routine differs per row; the provider's template holds the
      // action and the target activity.
      setOnClickFillInIntent(
          R.id.row_root,
          Intent().setData(Uri.parse("$TIMER_URI_PREFIX${Uri.encode(row.id)}")),
      )
    }
  }

  override fun getLoadingView(): RemoteViews? = null

  override fun getViewTypeCount() = 1

  override fun getItemId(position: Int) = position.toLong()

  override fun hasStableIds() = false

  /**
   * Formats the schema's local "HH:MM" against the phone's clock setting.
   *
   * Done here rather than in Dart so that turning 24-hour time on or off is
   * reflected without waiting for the app to publish again — the same reason
   * the in-app list formats through `MaterialLocalizations` instead of echoing
   * the stored string.
   */
  private fun formatStartTime(startTime: String?): String {
    if (startTime == null) return ""

    val parts = startTime.split(":")
    val hour = parts.getOrNull(0)?.toIntOrNull() ?: return ""
    val minute = parts.getOrNull(1)?.toIntOrNull() ?: return ""

    val time =
        Calendar.getInstance().apply {
          set(Calendar.HOUR_OF_DAY, hour)
          set(Calendar.MINUTE, minute)
          set(Calendar.SECOND, 0)
        }

    return DateFormat.getTimeFormat(context).format(time.time)
  }

  companion object {
    const val TIMER_URI_PREFIX = "openroutine://timer?routineId="
  }
}
