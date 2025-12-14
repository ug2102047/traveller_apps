import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/local_bookings.dart';
import '../utils/wishlist_service.dart';
import 'mock_wallet_payment_screen.dart';

enum WalletMethod { bkash, nagad }

class HotelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? hotel;
  const HotelDetailsScreen({this.hotel, super.key});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  int? _selectedRoomIndex;
  @override
  Widget build(BuildContext context) {
    final args =
        widget.hotel ??
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final data = args ?? <String, dynamic>{};
    final imageVal = (data['image'] ?? '') as String;

    Widget imageWidget;
    if (imageVal.isNotEmpty &&
        (imageVal.startsWith('http') || imageVal.startsWith('https'))) {
      imageWidget = Image.network(
        imageVal,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          height: 220,
          color: Colors.grey[200],
          child: const Icon(Icons.hotel, size: 80, color: Colors.grey),
        ),
      );
    } else if (imageVal.isNotEmpty) {
      imageWidget = Image.asset(
        imageVal,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          height: 220,
          color: Colors.grey[200],
          child: const Icon(Icons.hotel, size: 80, color: Colors.grey),
        ),
      );
    } else {
      imageWidget = Container(
        height: 220,
        color: Colors.blue[100],
        child: const Center(
          child: Icon(Icons.hotel, size: 80, color: Colors.white),
        ),
      );
    }

    // Rooms list support: hotel may include `rooms` as List<Map>
    final List<Map<String, dynamic>> rooms = [];
    if (data['rooms'] is List) {
      for (final r in data['rooms']) {
        if (r is Map<String, dynamic>) {
          rooms.add(r);
        } else if (r is Map) {
          rooms.add(Map<String, dynamic>.from(r));
        }
      }
    }

    final List<String> roomImages = [];
    if (data['room_images'] is List) {
      for (final ri in data['room_images']) {
        if (ri is String && ri.isNotEmpty) roomImages.add(ri);
      }
    } else if (rooms.isNotEmpty) {
      for (final r in rooms) {
        final img = (r['image'] ?? '') as String;
        if (img.isNotEmpty) roomImages.add(img);
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(data['name'] ?? 'Hotel Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
              const SizedBox(height: 12),
              Text(
                data['name'] ?? 'Unnamed Hotel',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (data['short_description'] != null)
                Text(data['short_description']),
              const SizedBox(height: 8),
              if (data['description'] != null) Text(data['description']),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (data['price_range'] != null)
                    Text(
                      'Price: ${data['price_range']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Spacer(),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _onBookPressed(data),
                    icon: const Icon(Icons.book_online),
                    label: const Text('Book'),
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('wishlists')
                        .where(
                          'userId',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                        )
                        .where('targetType', isEqualTo: 'hotel')
                        .where(
                          'targetId',
                          isEqualTo: (data['name'] ?? data['id'] ?? '')
                              .toString(),
                        )
                        .snapshots(),
                    builder: (ctx, snap) {
                      final isFav = (snap.data?.docs.isNotEmpty ?? false);
                      return ElevatedButton.icon(
                        onPressed: () async {
                          final target = (data['name'] ?? data['id'] ?? '')
                              .toString();
                          try {
                            if (isFav) {
                              await WishlistService.removeFromWishlist(
                                targetType: 'hotel',
                                targetId: target,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from wishlist'),
                                ),
                              );
                            } else {
                              await WishlistService.addToWishlist(
                                targetType: 'hotel',
                                targetId: target,
                                name: data['name'] ?? '',
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to wishlist'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Wishlist error: $e')),
                            );
                          }
                        },
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text(isFav ? 'Wishlisted' : 'Add to Wishlist'),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (rooms.isNotEmpty) ...[
                const Text(
                  'Rooms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final r = rooms[i];
                      final rImg = (r['image'] ?? '') as String;
                      final selected = (_selectedRoomIndex ?? 0) == i;
                      return InkWell(
                        onTap: () => setState(() => _selectedRoomIndex = i),
                        child: Container(
                          width: 260,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    rImg.isNotEmpty && rImg.startsWith('http')
                                    ? Image.network(
                                        rImg,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      )
                                    : rImg.isNotEmpty
                                    ? Image.asset(
                                        rImg,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 96,
                                        height: 96,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.bed),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      r['type'] ?? 'Room',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      r['description'] ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Price: ${r['price'] ?? '-'}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Selected room details card
                Builder(
                  builder: (ctx) {
                    final sel = _selectedRoomIndex ?? 0;
                    if (rooms.isEmpty) return const SizedBox.shrink();
                    final room = rooms.length > sel ? rooms[sel] : rooms[0];
                    final rImg = (room['image'] ?? '') as String;
                    final amenities = <String>[];
                    if (room['amenities'] is List) {
                      for (final a in room['amenities']) {
                        if (a is String) amenities.add(a);
                      }
                    }
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: rImg.isNotEmpty && rImg.startsWith('http')
                                  ? Image.network(
                                      rImg,
                                      width: 120,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : rImg.isNotEmpty
                                  ? Image.asset(
                                      rImg,
                                      width: 120,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 120,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.bed),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room['type'] ?? 'Room',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(room['description'] ?? ''),
                                  const SizedBox(height: 8),
                                  if (amenities.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: amenities
                                          .map((a) => Chip(label: Text(a)))
                                          .toList(),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Price: BDT ${room['price'] ?? '-'}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) {
                                            // reuse existing flow
                                            _onBookPressed(data);
                                            return;
                                          }
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (ctx2) => Padding(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(
                                                  ctx2,
                                                ).viewInsets.bottom,
                                              ),
                                              child: BookingSheet(
                                                hotelData: data,
                                                userId: user.uid,
                                                initialRoomTypeIndex: sel,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Book this room'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (roomImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: roomImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final img = roomImages[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: img.startsWith('http')
                            ? Image.network(
                                img,
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                img,
                                width: 160,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // If there are no explicit room entries, show a fallback Room Details card
              if (rooms.isEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Show room details dialog (fallback)
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          final price =
                              data['price_range'] ?? data['price'] ?? '-';
                          final amenities = (data['amenities'] is List)
                              ? List<String>.from(data['amenities'])
                              : <String>[];
                          return AlertDialog(
                            title: const Text('Room Details'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (price != null)
                                    Text(
                                      'Price: $price',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(data['description'] ?? ''),
                                  const SizedBox(height: 12),
                                  if (amenities.isNotEmpty) ...[
                                    const Text(
                                      'Amenities',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: amenities
                                          .map((a) => Chip(label: Text(a)))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    _onBookPressed(data);
                                    return;
                                  }
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx2) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(
                                          ctx2,
                                        ).viewInsets.bottom,
                                      ),
                                      child: BookingSheet(
                                        hotelData: data,
                                        userId: user.uid,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Book'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Room Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['price_range'] ??
                                      data['price'] ??
                                      'Price not listed',
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (data['contact'] != null) Text('Contact: ${data['contact']}'),
              if (data['address'] != null) Text('Address: ${data['address']}'),
              const SizedBox(height: 12),
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final hotelName = (data['name'] ?? '').toString();
                  final hotelId = (data['id'] ?? data['hotel_id'] ?? '')
                      .toString();
                  final target = hotelName.isNotEmpty ? hotelName : hotelId;
                  if (target.isEmpty) return const Text('No reviews yet.');

                  return StreamBuilder<QuerySnapshot>(
                    // Query only by `target` to avoid requiring a composite
                    // index on Firestore; we'll sort by `created_at` locally.
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('target', isEqualTo: target)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Text('Error loading reviews: ${snap.error}');
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) return const Text('No reviews yet.');

                      final docsList = List<QueryDocumentSnapshot>.from(docs);
                      docsList.sort((a, b) {
                        final aMap = a.data() as Map<String, dynamic>;
                        final bMap = b.data() as Map<String, dynamic>;
                        final aTs = aMap['created_at'];
                        final bTs = bMap['created_at'];
                        if (aTs is Timestamp && bTs is Timestamp) {
                          return bTs.compareTo(aTs);
                        }
                        return 0;
                      });

                      return Column(
                        children: docsList.map((d) {
                          final r = d.data() as Map<String, dynamic>;
                          final user = (r['user'] ?? r['userId'] ?? 'Anonymous')
                              .toString();
                          final comment = (r['comment'] ?? '').toString();
                          final rating = (r['rating'] ?? 0).toString();
                          final targetName = (r['target'] ?? '').toString();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(user),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment),
                                  if (targetName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        'Place: $targetName',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(rating),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/review',
                    arguments: {
                      'targetType': 'hotel',
                      'target': (data['name'] ?? data['id'] ?? '').toString(),
                    },
                  );
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('Add a Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBookPressed(Map<String, dynamic> hotelData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Prompt to login or signup
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text('You must be signed in to book a hotel.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/login');
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/signup');
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      );
      return;
    }

    // Open booking bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: BookingSheet(hotelData: hotelData, userId: user.uid),
      ),
    );
  }
}

class BookingSheet extends StatefulWidget {
  final Map<String, dynamic> hotelData;
  final String userId;
  final int initialRoomTypeIndex;
  const BookingSheet({
    required this.hotelData,
    required this.userId,
    this.initialRoomTypeIndex = 0,
    super.key,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  DateTime? checkIn;
  DateTime? checkOut;
  int rooms = 1;
  int roomTypeIndex = 0;
  WalletMethod walletMethod = WalletMethod.bkash;
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        checkIn = picked;
      } else {
        checkOut = picked;
      }
    });
  }

  void initState() {
    super.initState();
    roomTypeIndex = widget.initialRoomTypeIndex;
  }

  Future<void> _submitBooking() async {
    if (checkIn == null || checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (checkOut!.isBefore(checkIn!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out must be after check-in')),
      );
      return;
    }
    double totalAmount = 0.0;
    double amountToPay = 0.0;
    setState(() => loading = true);
    try {
      final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
      // Determine unit price
      double unitPrice = 1000.0;
      if (widget.hotelData['rooms'] is List &&
          widget.hotelData['rooms'].isNotEmpty) {
        try {
          final rp = widget.hotelData['rooms'][roomTypeIndex]['price'];
          if (rp is num) unitPrice = rp.toDouble();
          if (rp is String) unitPrice = double.tryParse(rp) ?? unitPrice;
        } catch (_) {}
      } else if (widget.hotelData['price'] != null) {
        final p = widget.hotelData['price'];
        if (p is num) unitPrice = p.toDouble();
        if (p is String) unitPrice = double.tryParse(p) ?? unitPrice;
      }
      final totalAmount = unitPrice * rooms;
      final amountToPay = (totalAmount * 0.20);

      // Open mock payment to simulate wallet (advance only)
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MockWalletPaymentScreen(amount: amountToPay),
        ),
      );
      if (paid != true) {
        // user cancelled payment
        if (mounted) setState(() => loading = false);
        return;
      }
      final booking = {
        'userId': widget.userId,
        'hotelId':
            widget.hotelData['id'] ?? widget.hotelData['name'] ?? 'unknown',
        'hotelName': widget.hotelData['name'] ?? '',
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'checkIn': Timestamp.fromDate(checkIn!),
        'checkOut': Timestamp.fromDate(checkOut!),
        'rooms': rooms,
        'status': 'pending',
        'paymentMethod': walletMethod == WalletMethod.bkash ? 'bKash' : 'Nagad',
        'paymentStatus': 'partial',
        'paidAmount': amountToPay,
        'totalAmount': totalAmount,
        'created_at': FieldValue.serverTimestamp(),
        // local metadata for fallback
        'localId': localId,
        'synced': true,
      };
      // Debug: print current auth uid and booking payload before write
      try {
        final authUid = FirebaseAuth.instance.currentUser?.uid;
        // ignore: avoid_print
        print('Submitting booking. authUid=$authUid booking=$booking');
      } catch (_) {}
      await FirebaseFirestore.instance.collection('bookings').add(booking);
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Booked'),
          content: const Text('Your booking request was submitted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // If write fails due to permissions or network, save locally for now
      try {
        final localBooking = {
          'localId': 'local-${DateTime.now().millisecondsSinceEpoch}',
          'userId': widget.userId,
          'hotelId':
              widget.hotelData['id'] ?? widget.hotelData['name'] ?? 'unknown',
          'hotelName': widget.hotelData['name'] ?? '',
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'checkIn': checkIn!.toIso8601String(),
          'checkOut': checkOut!.toIso8601String(),
          'rooms': rooms,
          'status': 'pending',
          'synced': false,
          'created_at': DateTime.now().toIso8601String(),
          'paymentMethod': walletMethod == WalletMethod.bkash
              ? 'bKash'
              : 'Nagad',
          'paymentStatus': 'partial',
          'paidAmount': amountToPay,
          'totalAmount': totalAmount,
        };
        await saveLocalBooking(localBooking);
        if (!mounted) return;
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Offline Saved'),
            content: const Text(
              'Booking could not be saved to server and was saved locally. It will be synced when server rules allow.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Booking failed'),
            content: SingleChildScrollView(child: Text(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Book Hotel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter phone number'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final val = v.trim();
                  if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(val)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text(
                        checkIn == null
                            ? 'Select check-in'
                            : 'Check-in: ${checkIn!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text(
                        checkOut == null
                            ? 'Select check-out'
                            : 'Check-out: ${checkOut!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Rooms:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: rooms,
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (e) => DropdownMenuItem(value: e, child: Text('$e')),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => rooms = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Room type selector if multiple room types available
              if (widget.hotelData['rooms'] is List &&
                  widget.hotelData['rooms'].isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Room type:'),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: roomTypeIndex,
                  items: List<DropdownMenuItem<int>>.generate(
                    widget.hotelData['rooms'].length,
                    (i) {
                      final r =
                          widget.hotelData['rooms'][i] as Map<String, dynamic>;
                      final title = (r['type'] ?? r['name'] ?? 'Room ${i + 1}')
                          .toString();
                      return DropdownMenuItem(value: i, child: Text(title));
                    },
                  ),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => roomTypeIndex = v);
                  },
                ),
              ],
              const SizedBox(height: 12),
              // Display calculated total and payment options
              Builder(
                builder: (ctx) {
                  double unitPrice = 1000.0;
                  if (widget.hotelData['rooms'] is List &&
                      widget.hotelData['rooms'].isNotEmpty) {
                    final rp =
                        widget.hotelData['rooms'][roomTypeIndex]['price'];
                    if (rp is num) unitPrice = rp.toDouble();
                    if (rp is String)
                      unitPrice = double.tryParse(rp) ?? unitPrice;
                  } else if (widget.hotelData['price'] != null) {
                    final p = widget.hotelData['price'];
                    if (p is num) unitPrice = p.toDouble();
                    if (p is String)
                      unitPrice = double.tryParse(p) ?? unitPrice;
                  }
                  final total = unitPrice * rooms;
                  final advance = total * 0.20;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit price: BDT ${unitPrice.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      Text('Total: BDT ${total.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      const Text('Payment method (advance required):'),
                      RadioListTile<WalletMethod>(
                        title: const Text('bKash (20% advance)'),
                        value: WalletMethod.bkash,
                        groupValue: walletMethod,
                        onChanged: (v) {
                          if (v != null) setState(() => walletMethod = v);
                        },
                      ),
                      RadioListTile<WalletMethod>(
                        title: const Text('Nagad (20% advance)'),
                        value: WalletMethod.nagad,
                        groupValue: walletMethod,
                        onChanged: (v) {
                          if (v != null) setState(() => walletMethod = v);
                        },
                      ),
                      Text(
                        'Advance due now: BDT ${advance.toStringAsFixed(0)}',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _submitBooking,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Booking'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
