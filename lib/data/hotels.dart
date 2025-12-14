// Local hotels dataset
// Each hotel is a Map<String, dynamic> with keys:
// id, name, address, phone, rating, price_range, amenities (List<String>), image, district, latitude, longitude, description

final List<Map<String, dynamic>> hotels = [
  {
    'id': 'st1',
    'name': 'Blue Ocean Resort (Saint Martin)',
    'address': 'Near Saint Martin Jetty, Teknaf, Cox\'s Bazar',
    'phone': '+880 1711-000000',
    'rating': 4.3,
    'price_range': 'BDT 4000-8000',
    'amenities': [
      'Free WiFi',
      'Restaurant',
      'Sea View',
      'Hot Water',
      'Boat Service',
    ],
    'image':
        'https://images.unsplash.com/photo-1501117716987-c8e3b1bb0b0d?w=1200&q=80',
    'district': 'Cox\'s Bazar',
    'latitude': 20.6305,
    'longitude': 92.3334,
    'description':
        'Comfortable seaside resort with quick access to Saint Martin island via boat. Suitable for families and groups.',
  },
  {
    'id': 'st2',
    'name': 'Sea Pearl Hotel',
    'address': 'Beachfront, Saint Martin Access Point, Teknaf',
    'phone': '+880 1711-000001',
    'rating': 4.1,
    'price_range': 'BDT 3000-6000',
    'amenities': [
      'Breakfast Included',
      'Airport Transfer',
      'Private Beach',
      'Parking',
    ],
    'image':
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80',
    'district': 'Cox\'s Bazar',
    'latitude': 20.6300,
    'longitude': 92.3330,
    'description':
        'Small beachfront hotel offering easy boat access to Saint Martin. Clean rooms and friendly staff.',
  },
  {
    'id': 'st3',
    'name': 'Coral Bay Guest House',
    'address': 'Teknaf Beach Road, near Saint Martin boats',
    'phone': '+880 1711-000002',
    'rating': 3.8,
    'price_range': 'BDT 1800-3500',
    'amenities': ['Sea View', 'Family Rooms', 'Restaurant'],
    'image':
        'https://images.unsplash.com/photo-1493558103817-58b2924bce98?w=1200&q=80',
    'district': 'Cox\'s Bazar',
    'latitude': 20.6290,
    'longitude': 92.3320,
    'description':
        'Budget-friendly guest house close to the Saint Martin boat terminal. Good value for short stays.',
  },
  {
    'id': 'st4',
    'name': 'Island Breeze Cottages',
    'address': 'Near Saint Martin Pier, Teknaf',
    'phone': '+880 1711-000003',
    'rating': 4.0,
    'price_range': 'BDT 3500-6500',
    'amenities': ['Cottages', 'Sea View', 'Boat Assistance', 'Breakfast'],
    'image':
        'https://images.unsplash.com/photo-1499696013213-6f3b1a8f8e64?w=1200&q=80',
    'district': 'Cox\'s Bazar',
    'latitude': 20.6310,
    'longitude': 92.3340,
    'description':
        'Cozy cottages offering privacy and direct access to nearby boat services to Saint Martin.',
  },
];
