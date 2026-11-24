/// Center/Teacher white-label config, subscription & theme tokens.

class TenantModel {
  final String tenantId;
  final String name;
  final String subdomain;
  final String accentColor;
  final String primaryColor;
  final bool isActive;
  final String subscriptionTier;
  final DateTime subscriptionExpiresAt;

  const TenantModel({
    required this.tenantId,
    required this.name,
    required this.subdomain,
    required this.accentColor,
    required this.primaryColor,
    required this.isActive,
    required this.subscriptionTier,
    required this.subscriptionExpiresAt,
  });

  TenantModel copyWith({
    String? tenantId,
    String? name,
    String? subdomain,
    String? accentColor,
    String? primaryColor,
    bool? isActive,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
  }) => TenantModel(
    tenantId: tenantId ?? this.tenantId,
    name: name ?? this.name,
    subdomain: subdomain ?? this.subdomain,
    accentColor: accentColor ?? this.accentColor,
    primaryColor: primaryColor ?? this.primaryColor,
    isActive: isActive ?? this.isActive,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
  );

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'name': name,
      'subdomain': subdomain,
      'accentColor': accentColor,
      'primaryColor': primaryColor,
      'isActive': isActive,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiresAt': subscriptionExpiresAt.toIso8601String(),
    };
  }

  factory TenantModel.fromMap(Map<String, dynamic> map) {
    return TenantModel(
      tenantId: map['tenantId'] as String,
      name: map['name'] as String,
      subdomain: map['subdomain'] as String,
      accentColor: map['accentColor'] as String,
      primaryColor: map['primaryColor'] as String,
      isActive: map['isActive'] as bool,
      subscriptionTier: map['subscriptionTier'] as String,
      subscriptionExpiresAt: DateTime.parse(map['subscriptionExpiresAt'] as String),
    );
  }

  @override
  String toString() => 'TenantModel{$tenantId: $name}';
}
