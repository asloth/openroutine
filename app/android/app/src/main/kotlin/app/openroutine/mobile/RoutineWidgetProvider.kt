package app.openroutine.mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The home screen widget: the user's routines, one tap from Timer Mode.
 *
 * The class name is part of the contract with the Dart side — it is what
 * `HomeWidgetPublisher.androidProviderName` asks the plugin to redraw.
 */
class RoutineWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val snapshot = RoutineSnapshot.read(context, widgetData)

    for (widgetId in appWidgetIds) {
      val views =
          RemoteViews(context.packageName, R.layout.routine_widget).apply {
            setTextViewText(R.id.widget_title, snapshot.title)
            setTextViewText(R.id.widget_empty, snapshot.empty)

            setRemoteAdapter(R.id.routine_list, collectionIntent(context, widgetId))
            setEmptyView(R.id.routine_list, R.id.widget_empty)

            // Rows carry only the routine id; this template supplies everything
            // else. It has to be mutable, which is why it is built here rather
            // than with HomeWidgetLaunchIntent.getActivity — that one is
            // immutable, and an immutable template ignores fill-in intents, so
            // every row would open the same screen.
            setPendingIntentTemplate(R.id.routine_list, launchTemplate(context))

            // Nothing to launch yet: the empty state just opens the app.
            setOnClickPendingIntent(
                R.id.widget_empty,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse(OPEN_URI),
                ),
            )
          }

      appWidgetManager.updateAppWidget(widgetId, views)
      // updateAppWidget redraws the frame; the list only refetches its rows
      // when it is told the data behind them changed.
      appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.routine_list)
    }
  }

  /**
   * Distinct per widget id, because `RemoteViewsService` caches one factory per
   * intent: without the id in the data URI, two placed widgets would share a
   * single list.
   */
  private fun collectionIntent(context: Context, widgetId: Int): Intent =
      Intent(context, RoutineListService::class.java).apply {
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
      }

  private fun launchTemplate(context: Context): PendingIntent {
    val intent =
        Intent(context, MainActivity::class.java).apply {
          // The plugin recognises a launch by this action and reads the URI the
          // row fills in from the intent's data.
          action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }

    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      flags = flags or PendingIntent.FLAG_MUTABLE
    }

    return PendingIntent.getActivity(context, TEMPLATE_REQUEST_CODE, intent, flags)
  }

  companion object {
    const val OPEN_URI = "openroutine://open"
    private const val TEMPLATE_REQUEST_CODE = 1
  }
}
