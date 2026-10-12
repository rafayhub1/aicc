import '../models/activity_event.dart';
import '../models/app_notification.dart';
import '../models/inbox_item.dart';
import '../models/student_document.dart';
import 'activity_service.dart';
import 'api_service.dart';

class InboxService {
  InboxService({required this.api, required this.activity});

  final ApiService api;
  final ActivityService activity;

  Future<List<InboxItem>> load({
    required String studentId,
  }) async {
    final results = await Future.wait([
      api.getNotifications(studentId),
      api.getDocuments(studentId),
      activity.listForCurrentUser(),
    ]);
    final notifications = results[0] as List<AppNotification>;
    final documents = results[1] as List<StudentDocument>;
    final events = results[2] as List<ActivityEvent>;

    final items = <InboxItem>[
      for (final notification in notifications)
        _fromBackend(notification, documents, studentId),
      for (final event in events) _fromActivity(event),
    ];
    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  Future<void> markRead(InboxItem item, String studentId) async {
    if (item.read) return;
    if (item.source == 'backend') {
      await api.markNotificationRead(studentId, item.id);
      return;
    }
    await activity.markRead(item.id);
  }

  Future<void> remove(InboxItem item, String studentId) async {
    if (item.source == 'backend') {
      await api.deleteNotification(studentId, item.id);
      return;
    }
    await activity.delete(item.id);
  }

  InboxItem _fromBackend(
    AppNotification notification,
    List<StudentDocument> documents,
    String studentId,
  ) {
    final docType = switch (notification.type) {
      'fee_challan_ready' => 'fee_challan',
      'roll_slip_ready' => 'roll_number_slip',
      _ => null,
    };
    StudentDocument? document;
    if (docType != null) {
      for (final candidate in documents) {
        if (candidate.docType == docType) {
          document = candidate;
          break;
        }
      }
    }
    final page = document ??
        (docType == null
            ? null
            : StudentDocument(id: docType, docType: docType, status: 'pending'));
    return InboxItem(
      id: notification.id,
      source: 'backend',
      type: notification.type,
      title: _backendTitle(notification.type),
      body: notification.message,
      time: notification.timestamp,
      read: notification.read,
      documentUrl: page?.resolvedUrl(api.baseUrl, studentId),
      documentTitle: switch (notification.type) {
        'fee_challan_ready' => 'Fee challan',
        'roll_slip_ready' => 'Roll number slip',
        _ => null,
      },
    );
  }

  InboxItem _fromActivity(ActivityEvent event) {
    return InboxItem(
      id: event.id,
      source: 'local',
      type: event.type,
      title: _activityTitle(event.type),
      body: _activityBody(event.type),
      time: event.timestamp,
      read: event.read,
    );
  }

  String _backendTitle(String type) {
    return switch (type) {
      'fee_challan_ready' => 'Fee challan ready',
      'roll_slip_ready' => 'Roll number slip ready',
      'sign_in' => 'Sign-in reminder',
      _ => 'Notice',
    };
  }

  String _activityTitle(String type) {
    return switch (type) {
      'signup' => 'Signed up successfully',
      'login' => 'Logged in',
      'logout' => 'Logged out',
      'chat_completed' => 'Chat completed',
      _ => 'Activity',
    };
  }

  String _activityBody(String type) {
    return switch (type) {
      'signup' => 'Your AICC account was created.',
      'login' => 'You signed in to AICC.',
      'logout' => 'You signed out of AICC.',
      'chat_completed' => 'A chat with the assistant was saved.',
      _ => 'Something happened on your account.',
    };
  }
}
