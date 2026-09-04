import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Current schema version for stored [Entry] records.
/// Bump this — and add a migration in DatabaseService — whenever the shape changes.
const entrySchemaVersion = 1;

enum EntryKind { home, away, skip }

enum DayPart { morning, afternoon, evening }

enum Roast { light, medium, dark }

enum VenueTag { cafe, convenience, office, other }

extension EntryKindX on EntryKind {
  String get id => name;
  static EntryKind fromId(String id) =>
      EntryKind.values.firstWhere((e) => e.name == id, orElse: () => EntryKind.home);
}

extension DayPartX on DayPart {
  String get id => name;
  String get label => switch (this) {
        DayPart.morning => 'Morning',
        DayPart.afternoon => 'Afternoon',
        DayPart.evening => 'Evening',
      };
  static DayPart? fromId(String? id) {
    if (id == null) return null;
    for (final e in DayPart.values) {
      if (e.name == id) return e;
    }
    return null;
  }
}

extension RoastX on Roast {
  String get id => name;
  String get label => switch (this) {
        Roast.light => 'Light',
        Roast.medium => 'Medium',
        Roast.dark => 'Dark',
      };
  static Roast? fromId(String? id) {
    if (id == null) return null;
    for (final e in Roast.values) {
      if (e.name == id) return e;
    }
    return null;
  }
}

extension VenueTagX on VenueTag {
  String get id => name;
  String get label => switch (this) {
        VenueTag.cafe => 'Café',
        VenueTag.convenience => 'Convenience store',
        VenueTag.office => 'Office',
        VenueTag.other => 'Other',
      };
  static VenueTag? fromId(String? id) {
    if (id == null) return null;
    for (final e in VenueTag.values) {
      if (e.name == id) return e;
    }
    return null;
  }
}

/// A single logged cup — or a "no coffee today" skip marker that keeps a streak alive
/// without implying anything was consumed.
class Entry {
  final String id;
  final EntryKind kind;
  final DateTime date; // date-only (no time component)
  final String? method;
  final double? price;
  final bool free;
  final int rating; // 0-5
  final String? caption;
  final String? notes;
  final String? photoPath;
  final DayPart? timeOfDay;
  final List<String> flavors;
  final Roast? roast;
  final VenueTag? venueTag;
  final String? venueName;
  final bool isSample;

  const Entry({
    required this.id,
    required this.kind,
    required this.date,
    this.method,
    this.price,
    this.free = false,
    this.rating = 0,
    this.caption,
    this.notes,
    this.photoPath,
    this.timeOfDay,
    this.flavors = const [],
    this.roast,
    this.venueTag,
    this.venueName,
    this.isSample = false,
  });

  static String newId() => _uuid.v4();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  factory Entry.skip({required DateTime date}) => Entry(
        id: newId(),
        kind: EntryKind.skip,
        date: dateOnly(date),
      );

  Entry copyWith({
    String? id,
    EntryKind? kind,
    DateTime? date,
    String? method,
    double? price,
    bool? free,
    int? rating,
    String? caption,
    String? notes,
    String? photoPath,
    DayPart? timeOfDay,
    List<String>? flavors,
    Roast? roast,
    VenueTag? venueTag,
    String? venueName,
    bool? isSample,
    bool clearPrice = false,
    bool clearMethod = false,
    bool clearCaption = false,
    bool clearNotes = false,
    bool clearPhoto = false,
    bool clearTimeOfDay = false,
    bool clearRoast = false,
    bool clearVenue = false,
  }) {
    return Entry(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      method: clearMethod ? null : (method ?? this.method),
      price: clearPrice ? null : (price ?? this.price),
      free: free ?? this.free,
      rating: rating ?? this.rating,
      caption: clearCaption ? null : (caption ?? this.caption),
      notes: clearNotes ? null : (notes ?? this.notes),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      timeOfDay: clearTimeOfDay ? null : (timeOfDay ?? this.timeOfDay),
      flavors: flavors ?? this.flavors,
      roast: clearRoast ? null : (roast ?? this.roast),
      venueTag: clearVenue ? null : (venueTag ?? this.venueTag),
      venueName: clearVenue ? null : (venueName ?? this.venueName),
      isSample: isSample ?? this.isSample,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'kind': kind.id,
      'date': dateIso,
      'method': method,
      'price': price,
      'free': free ? 1 : 0,
      'rating': rating,
      'caption': caption,
      'notes': notes,
      'photo_path': photoPath,
      'time_of_day': timeOfDay?.id,
      'flavors': flavors.join(','),
      'roast': roast?.id,
      'venue_tag': venueTag?.id,
      'venue_name': venueName,
      'is_sample': isSample ? 1 : 0,
      'schema_version': entrySchemaVersion,
    };
  }

  factory Entry.fromMap(Map<String, Object?> m) {
    return Entry(
      id: m['id'] as String,
      kind: EntryKindX.fromId(m['kind'] as String),
      date: DateTime.parse(m['date'] as String),
      method: m['method'] as String?,
      price: (m['price'] as num?)?.toDouble(),
      free: (m['free'] as int? ?? 0) == 1,
      rating: m['rating'] as int? ?? 0,
      caption: m['caption'] as String?,
      notes: m['notes'] as String?,
      photoPath: m['photo_path'] as String?,
      timeOfDay: DayPartX.fromId(m['time_of_day'] as String?),
      flavors: ((m['flavors'] as String?) ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      roast: RoastX.fromId(m['roast'] as String?),
      venueTag: VenueTagX.fromId(m['venue_tag'] as String?),
      venueName: m['venue_name'] as String?,
      isSample: (m['is_sample'] as int? ?? 0) == 1,
    );
  }

  String get dateIso =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
