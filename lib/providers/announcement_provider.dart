import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import '../services/api_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getAnnouncements();
      _announcements = data.map<Announcement>((json) => Announcement.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Duyurular yüklenemedi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    try {
      await _apiService.createAnnouncement(
        title: title,
        content: content,
        isPinned: isPinned,
      );
      await fetchAnnouncements();
      return true;
    } catch (e) {
      _error = 'Duyuru eklenemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAnnouncement(int announcementId, Map<String, dynamic> data) async {
    try {
      await _apiService.updateAnnouncement(
        announcementId,
        title: data['title'],
        content: data['content'],
        isPinned: data['is_pinned'],
        isActive: data['is_active'],
      );
      await fetchAnnouncements();
      return true;
    } catch (e) {
      _error = 'Duyuru güncellenemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAnnouncement(int announcementId) async {
    try {
      await _apiService.deleteAnnouncement(announcementId);
      await fetchAnnouncements();
      return true;
    } catch (e) {
      _error = 'Duyuru silinemedi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
