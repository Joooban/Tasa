/// Shared vocabulary used by both the entry form and badge/insight computation.
/// Kept as plain lists (not enums) because users can free-type a custom method
/// via "Other…", exactly like the prototype.
const List<String> kBrewMethods = [
  // PH café-familiar drinks first — more people pick these than a home
  // brew method when logging a cup.
  'Cappuccino',
  'Latte',
  'Flat White',
  'Caramel Macchiato',
  'Spanish Latte',
  'Vanilla Latte',
  'Mocha',
  'Sea Salt Latte',
  'Matcha Latte',
  'Ube Latte',
  'Pour-over (V60)',
  'Chemex',
  'AeroPress',
  'French press',
  'Moka pot',
  'Espresso',
  'Americano',
  'Cold brew',
  'Drip / auto-drip',
  'Sachet coffee (3-in-1)',
  'Instant',
];

const List<String> kFlavorTags = [
  'Fruity',
  'Floral',
  'Nutty',
  'Chocolatey',
  'Caramel',
  'Earthy',
  'Bright/Acidic',
  'Bitter',
];

const double kFallbackAwayPrice = 150;
