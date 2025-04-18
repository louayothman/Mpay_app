import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';

class UserRatingScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserRatingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserRatingScreen> createState() => _UserRatingScreenState();
}

class _UserRatingScreenState extends State<UserRatingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  double _currentRating = 0;
  double _userRating = 0;
  int _totalRatings = 0;
  List<Map<String, dynamic>> _reviews = [];
  final _reviewController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }
  
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRatingData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user rating data
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userRating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
          _totalRatings = (userData['totalRatings'] as num?)?.toInt() ?? 0;
        });
      }
      
      // Get current user's rating for this user
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final ratingDoc = await _firestore
            .collection('ratings')
            .where('raterId', isEqualTo: currentUser.uid)
            .where('userId', isEqualTo: widget.userId)
            .get();
        
        if (ratingDoc.docs.isNotEmpty) {
          final ratingData = ratingDoc.docs.first.data();
          setState(() {
            _currentRating = (ratingData['rating'] as num).toDouble();
            _reviewController.text = ratingData['review'] ?? '';
          });
        }
      }
      
      // Get reviews
      final reviewsQuery = await _firestore
          .collection('ratings')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> reviews = [];
      
      for (var doc in reviewsQuery.docs) {
        final reviewData = doc.data();
        
        // Get rater info
        final raterDoc = await _firestore.collection('users').doc(reviewData['raterId']).get();
        if (raterDoc.exists) {
          final raterData = raterDoc.data() as Map<String, dynamic>;
          reviewData['raterName'] = '${raterData['firstName']} ${raterData['lastName']}';
        } else {
          reviewData['raterName'] = 'مستخدم Mpay';
        }
        
        reviews.add(reviewData as Map<String, dynamic>);
      }
      
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _submitRating() async {
    if (_currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تقييم')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Check if user has already rated
        final ratingQuery = await _firestore
            .collection('ratings')
            .where('raterId', isEqualTo: currentUser.uid)
            .where('userId', isEqualTo: widget.userId)
            .get();
        
        if (ratingQuery.docs.isNotEmpty) {
          // Update existing rating
          await _firestore.collection('ratings').doc(ratingQuery.docs.first.id).update({
            'rating': _currentRating,
            'review': _reviewController.text.trim(),
            'updatedAt': Timestamp.now(),
          });
        } else {
          // Create new rating
          await _firestore.collection('ratings').add({
            'raterId': currentUser.uid,
            'userId': widget.userId,
            'rating': _currentRating,
            'review': _reviewController.text.trim(),
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
          
          // Update user's total ratings count
          await _firestore.collection('users').doc(widget.userId).update({
            'totalRatings': FieldValue.increment(1),
          });
        }
        
        // Calculate new average rating
        final ratingsQuery = await _firestore
            .collection('ratings')
            .where('userId', isEqualTo: widget.userId)
            .get();
        
        double totalRating = 0;
        int count = ratingsQuery.docs.length;
        
        for (var doc in ratingsQuery.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }
        
        double newRating = count > 0 ? totalRating / count : 0;
        
        // Update user's rating
        await _firestore.collection('users').doc(widget.userId).update({
          'rating': newRating,
        });
        
        // Show success message
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال التقييم بنجاح')),
        );
        
        // Reload data
        _loadRatingData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم المستخدم'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 24),
                              const SizedBox(width: 4),
                              Text(
                                _userRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' (${_totalRatings.toString()} تقييم)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Rate user
                  if (widget.userId != _auth.currentUser?.uid)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'قيّم هذا المستخدم',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Star rating
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < _currentRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _currentRating = index + 1;
                                      });
                                    },
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Review
                            TextFormField(
                              controller: _reviewController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'اكتب مراجعتك (اختياري)',
                                hintText: 'شارك تجربتك مع هذا المستخدم',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitRating,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('إرسال التقييم'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.userId != _auth.currentUser?.uid) const SizedBox(height: 24),
                  
                  // Reviews
                  const Text(
                    'التقييمات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _reviews.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد تقييمات بعد',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : Column(
                          children: _reviews.map((review) {
                            return _buildReviewCard(review);
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num).toDouble();
    final reviewText = review['review'] ?? '';
    final raterName = review['raterName'];
    final createdAt = review['createdAt'] as Timestamp;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rater info and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  raterName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            
            // Date
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            // Review text
            if (reviewText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  reviewText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}/${date.month}/${date.day}';
  }
}
