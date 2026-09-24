import 'package:flutter/material.dart';

enum InspectionStatus {
  draft,
  capturing,
  imagesReady,
  analyzing,
  aiAssessed,
  pendingValidation,
  validated,
  reportGenerated,
  completed,
}

enum SyncStatus {
  localOnly,
  pendingSync,
  syncing,
  synced,
  syncFailed,
}

enum OnionClass {
  healthy,
  damaged,
  blackRot,
  mold,
  softRot,
  sprouted,
  rotten,
  undersized,
  unknown,
}

enum SizeCategory {
  small,
  normal,
  large,
}

class AppConstants {
  static const String appName = 'OnionGrading AI';
  static const String appSubTitle = 'On-Device Procurement Quality System';
  static const String defaultRulesVersion = 'v1.0-demo';

  // Onion Varieties
  static const List<String> onionVarieties = [
    'Red Onion',
    'White Onion',
    'Yellow Onion',
    'Shallot / Small Onion',
  ];

  // Procurement Centers
  static const List<Map<String, String>> procurementCenters = [
    {
      'id': 'center-erode-01',
      'code': 'ERO-01',
      'name': 'Erode Onion Procurement Center',
      'location': 'Erode, Tamil Nadu',
      'district': 'Erode',
      'state': 'Tamil Nadu',
    },
    {
      'id': 'center-nashik-01',
      'code': 'PC-NSK-01',
      'name': 'Lasalgaon Onion APMC Center',
      'location': 'Lasalgaon, Nashik, Maharashtra',
      'district': 'Nashik',
      'state': 'Maharashtra',
    },
    {
      'id': 'center-pune-02',
      'code': 'PC-PUN-02',
      'name': 'Pune Gultekdi Market Yard',
      'location': 'Gultekdi, Pune, Maharashtra',
      'district': 'Pune',
      'state': 'Maharashtra',
    },
    {
      'id': 'center-indore-03',
      'code': 'PC-IND-03',
      'name': 'Devi Ahilya Bai Holkar APMC',
      'location': 'Indore, Madhya Pradesh',
      'district': 'Indore',
      'state': 'Madhya Pradesh',
    },
  ];

  static String formatOnionClass(OnionClass onionClass) {
    switch (onionClass) {
      case OnionClass.healthy:
        return 'Healthy';
      case OnionClass.damaged:
        return 'Damaged';
      case OnionClass.blackRot:
        return 'Black Rot';
      case OnionClass.mold:
        return 'Mold';
      case OnionClass.softRot:
        return 'Soft Rot';
      case OnionClass.sprouted:
        return 'Sprouted';
      case OnionClass.rotten:
        return 'Rotten';
      case OnionClass.undersized:
        return 'Undersized';
      case OnionClass.unknown:
        return 'Unknown';
    }
  }

  static OnionClass parseOnionClass(String value) {
    switch (value.toLowerCase().replaceAll('_', '').replaceAll(' ', '').trim()) {
      case 'healthy':
        return OnionClass.healthy;
      case 'damaged':
        return OnionClass.damaged;
      case 'blackrot':
        return OnionClass.blackRot;
      case 'mold':
        return OnionClass.mold;
      case 'softrot':
        return OnionClass.softRot;
      case 'sprouted':
        return OnionClass.sprouted;
      case 'rotten':
        return OnionClass.rotten;
      case 'undersized':
        return OnionClass.undersized;
      default:
        return OnionClass.unknown;
    }
  }

  static Color getClassColor(OnionClass onionClass) {
    switch (onionClass) {
      case OnionClass.healthy:
        return const Color(0xFF15803D); // Forest Green
      case OnionClass.damaged:
        return const Color(0xFFD97706); // Amber
      case OnionClass.blackRot:
        return const Color(0xFF1E293B); // Dark Charcoal
      case OnionClass.mold:
        return const Color(0xFF4338CA); // Deep Indigo
      case OnionClass.softRot:
        return const Color(0xFFDC2626); // Crimson Red
      case OnionClass.sprouted:
        return const Color(0xFF7C3AED); // Purple
      case OnionClass.rotten:
        return const Color(0xFFDC2626); // Crimson Red
      case OnionClass.undersized:
        return const Color(0xFF2563EB); // Blue
      case OnionClass.unknown:
        return const Color(0xFF6B7280); // Gray
    }
  }

  static String formatSyncStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.localOnly:
        return 'LOCAL ONLY';
      case SyncStatus.pendingSync:
        return 'PENDING SYNC';
      case SyncStatus.syncing:
        return 'SYNCING...';
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.syncFailed:
        return 'SYNC FAILED';
    }
  }

  static Color getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.localOnly:
        return const Color(0xFF64748B);
      case SyncStatus.pendingSync:
        return const Color(0xFFD97706);
      case SyncStatus.syncing:
        return const Color(0xFF2563EB);
      case SyncStatus.synced:
        return const Color(0xFF15803D);
      case SyncStatus.syncFailed:
        return const Color(0xFFDC2626);
    }
  }
}
