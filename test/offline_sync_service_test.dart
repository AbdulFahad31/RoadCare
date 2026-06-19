import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:road_care/features/report/models/ai_analysis.dart';
import 'package:road_care/features/report/services/offline_sync_service.dart';
import 'package:road_care/features/report/services/pothole_service.dart';
import 'package:road_care/features/report/services/storage_service.dart';

// Simple Mocks
class MockPotholeService extends Fake implements PotholeService {}

class MockStorageService extends Fake implements StorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiAnalysis Parsing Tests', () {
    test('handles various confidence formats successfully', () {
      // 1. confidence as int
      final jsonInt = {
        'damage_type': 'Pothole',
        'severity': 'High',
        'repair_priority': 'High',
        'estimated_diameter_cm': 35.0,
        'estimated_depth_cm': 5.0,
        'confidence': 85,
        'description': 'A deep pothole',
        'safety_warning': 'Avoid driving over it',
        'suggested_action': 'Repair'
      };
      expect(AiAnalysis.fromJson(jsonInt).confidence, 85);

      // 2. confidence as double
      final jsonDouble = {...jsonInt, 'confidence': 85.0};
      expect(AiAnalysis.fromJson(jsonDouble).confidence, 85);

      // 3. confidence as decimal representation of percentage
      final jsonDecimal = {...jsonInt, 'confidence': 0.85};
      expect(AiAnalysis.fromJson(jsonDecimal).confidence, 85);

      // 4. confidence as string representation of double
      final jsonStrDouble = {...jsonInt, 'confidence': '85.0'};
      expect(AiAnalysis.fromJson(jsonStrDouble).confidence, 85);

      // 5. confidence as string representation of decimal
      final jsonStrDecimal = {...jsonInt, 'confidence': '0.85'};
      expect(AiAnalysis.fromJson(jsonStrDecimal).confidence, 85);
    });
  });

  group('OfflineReport Serialization Tests', () {
    test('toJson and fromJson are symmetric', () {
      final now = DateTime.now();
      final report = OfflineReport(
        latitude: 12.345,
        longitude: 67.890,
        description: 'Test pothole',
        severity: 'high',
        userName: 'John Doe',
        userPhone: '1234567890',
        localImagePath: '/path/to/image.jpg',
        timestamp: now,
        damageType: 'Pothole',
        confidence: 90,
        aiGenerated: true,
      );

      final json = report.toJson();
      final decoded = OfflineReport.fromJson(json);

      expect(decoded.latitude, report.latitude);
      expect(decoded.longitude, report.longitude);
      expect(decoded.description, report.description);
      expect(decoded.severity, report.severity);
      expect(decoded.userName, report.userName);
      expect(decoded.userPhone, report.userPhone);
      expect(decoded.localImagePath, report.localImagePath);
      expect(decoded.timestamp.toIso8601String(),
          report.timestamp.toIso8601String());
      expect(decoded.damageType, report.damageType);
      expect(decoded.confidence, report.confidence);
      expect(decoded.aiGenerated, report.aiGenerated);
    });
  });

  group('OfflineSyncService Tests', () {
    late MockPotholeService mockPotholeService;
    late MockStorageService mockStorageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockPotholeService = MockPotholeService();
      mockStorageService = MockStorageService();
    });

    test('initializes with zero pending reports', () async {
      final service = OfflineSyncService(
        mockPotholeService,
        mockStorageService,
      );

      expect(service.state.pendingCount, 0);
      expect(service.state.isSyncing, false);
      service.dispose();
    });

    test('queues a report successfully', () async {
      final service = OfflineSyncService(
        mockPotholeService,
        mockStorageService,
      );

      final report = OfflineReport(
        latitude: 12.345,
        longitude: 67.890,
        description: 'Test pothole',
        severity: 'high',
        localImagePath: '/path/to/image.jpg',
        timestamp: DateTime.now(),
      );

      await service.queueReport(report);

      expect(service.state.pendingCount, 1);

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('offline_reports_queue');
      expect(list, isNotNull);
      expect(list!.length, 1);

      service.dispose();
    });
  });
}
