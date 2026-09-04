class _JokeBucket {
  final double max;
  final List<String> lines;
  const _JokeBucket(this.max, this.lines);
}

/// PH-flavored spend comparisons for the Wrapped card. Buckets by peso amount;
/// within a bucket the line is picked deterministically from a seed so the same
/// month always shows the same joke.
const List<_JokeBucket> _jokes = [
  _JokeBucket(50, [
    "that's about ten pieces of pandesal.",
    "a single day's mobile data promo.",
    'a pack of instant noodles, with change back.',
    'barely half a tricycle ride, if that were a thing.',
    'a text and call promo for the day.',
  ]),
  _JokeBucket(100, [
    'one tricycle ride around the block.',
    'a solo Chickenjoy, drink not included.',
    'a 3-day unlimited data promo.',
    'a short Grab ride to the next barangay.',
    'two packs of instant noodles and a soda.',
  ]),
  _JokeBucket(150, [
    'a modern-jeepney fare there and back, with change.',
    'a barbershop haircut.',
    'a week of unlimited mobile data.',
    'a Jollibee 2-piece meal.',
    'a tray of eggs from the sari-sari store.',
  ]),
  _JokeBucket(200, [
    'a movie ticket, no popcorn.',
    'a decent Grab ride across a few barangays.',
    'a case of bottled water for the week.',
    "a full day's parking downtown.",
    'a basic pair of flip-flops.',
  ]),
  _JokeBucket(250, [
    'a movie ticket with popcorn.',
    'a full load of laundry, wash and dry.',
    'a kilo of chicken from the wet market.',
    'a manicure at a budget salon.',
    'a toll run from one end of the expressway to the other.',
  ]),
  _JokeBucket(300, [
    'a month of one streaming plan.',
    'a proper salon haircut.',
    'dinner for one at a casual sit-down place.',
    'a full tank of gas for a scooter.',
    'a bowling game, shoe rental included.',
  ]),
  _JokeBucket(350, [
    'a basic t-shirt on sale.',
    'a paperback book.',
    'a fast food meal for two.',
    'a Grab ride clear across town in light traffic.',
    'two visits to a public gym day pass.',
  ]),
  _JokeBucket(400, [
    'a phone charger and cable set.',
    "an umbrella that'll actually survive typhoon season.",
    'two months of one streaming plan.',
    'a decent lunch buffet for one.',
    'a small grocery run, the essentials only.',
  ]),
  _JokeBucket(450, [
    'a Grab ride clear across the metro at normal traffic.',
    "a week's worth of home-cooked lunches, roughly.",
    'a full manicure and pedicure set.',
    'a mid-range drugstore makeup item.',
    'a month of a bigger mobile data plan.',
  ]),
  _JokeBucket(500, [
    "a decent dinner date, one person's share.",
    'a new pair of everyday rubber shoes, on sale.',
    'two days of groceries for a small household.',
    'two movie tickets with popcorn to share.',
    'a full car wash and vacuum.',
  ]),
  _JokeBucket(550, [
    'a Grab ride clear across the metro on a bad traffic day.',
    "a scooter's full tank with a little left over.",
    'dinner for two at a casual sit-down place.',
    'a month of unlimited data on a bigger plan.',
    'a haircut and a manicure in the same trip.',
  ]),
  _JokeBucket(600, [
    'a decent pair of rubber shoes, full price.',
    "a week's worth of groceries for one person.",
    'a nice dinner out, solo, no rush.',
    'a budget wireless earbuds case.',
    'a full tank for a scooter, snack after included.',
  ]),
  _JokeBucket(650, [
    'two full scooter tanks, back to back.',
    "a month's laundry, wash and dry, for one person.",
    'a casual dinner for two, drinks included.',
    'a decent pair of sneakers on sale.',
    'a haircut, a manicure, and a little left for merienda.',
  ]),
  _JokeBucket(700, [
    "a week's groceries for a small household.",
    'a mid-tier wireless earbuds set.',
    'a nice dinner for two at a sit-down place.',
    'two months of streaming.',
    'a full car wash and a scooter tank, same day.',
  ]),
  _JokeBucket(750, [
    'a nice dinner for two with dessert.',
    "a week's worth of jeepney and tricycle fares combined.",
    'a decent bag on sale.',
    'two tanks of gas for a scooter.',
    'a month at a budget gym.',
  ]),
  _JokeBucket(800, [
    'a full car wash package plus a scooter fill-up.',
    "a week's groceries for a small family.",
    'a decent pair of sneakers, full price.',
    'a mid-range Bluetooth speaker.',
    'dinner for two somewhere a little nicer.',
  ]),
  _JokeBucket(850, [
    'more than one full tank of gas for a small motorcycle.',
    'a good wireless earbuds set.',
    'a week of home-cooked meals for a small family.',
    'a nice bag, on sale.',
    'a haircut, a full mani-pedi, and merienda after.',
  ]),
  _JokeBucket(900, [
    'a nice dinner for two, somewhere with a view.',
    "a week's groceries for a family of three or four.",
    'a decent Bluetooth speaker, full price.',
    'two months of a bigger mobile data plan.',
    'a full detailing job for a scooter.',
  ]),
  _JokeBucket(950, [
    'about a quarter tank for a small car.',
    "a week's groceries plus snacks for a small family.",
    'a nice pair of sneakers, the good brand.',
    'a scooter tune-up at the shop.',
    'dinner for two at a proper restaurant, no rush.',
  ]),
  _JokeBucket(1000, [
    'a good pair of wireless earbuds.',
    "a week's transportation for the whole household.",
    'a solid grocery run for a small family.',
    'a scooter tune-up plus a full tank after.',
    'a nice dinner for two, dessert and all.',
  ]),
  _JokeBucket(3000, [
    "that's a full tank for a small car (about ₱2,400 to ₱2,600 at current pump prices).",
    'about a one-way Manila to Cebu flight on a good promo fare (promo fares run roughly '
        '₱1,928 to ₱2,052).',
    "roughly a month's Meralco bill for a small unit (about ₱1,800 to ₱2,400 for 150 to 200 kWh).",
    "that's a weekend's bus fare, there and back, plus meals.",
    'close to a mid-range wireless earbuds set.',
  ]),
  _JokeBucket(6000, [
    "that's a Manila to Cebu round trip, promo fares both ways.",
    'about a budget smartphone on a good sale.',
    "roughly two months' Meralco bill for a small unit.",
    "that's a weekend staycation, room included.",
    'close to a full grocery run for the month.',
  ]),
  _JokeBucket(double.infinity, [
    "that's new phone territory, no installment plan needed.",
    "that's a plane ticket somewhere with a beach, round trip.",
    "about a month's rent for a small room.",
    'roughly a weekend trip to Boracay, flights included.',
    "that's a proper appliance, an aircon unit maybe.",
  ]),
];

/// [seed] should be something stable per period, e.g. entry count — mirrors the
/// prototype's use of `state.entries.length` so the joke doesn't flicker on rerender.
String jokeFor(double amount, int seed) {
  final bucket = _jokes.firstWhere((j) => amount <= j.max, orElse: () => _jokes.last);
  final idx = (amount.floor() + seed) % bucket.lines.length;
  return bucket.lines[idx];
}
