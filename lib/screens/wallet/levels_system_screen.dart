import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mpay_app/models/data_models.dart';

class LevelsSystemScreen extends StatefulWidget {
  const LevelsSystemScreen({super.key});

  @override
  State<LevelsSystemScreen> createState() => _LevelsSystemScreenState();
}

class _LevelsSystemScreenState extends State<LevelsSystemScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _currentLevel = 'bronze';
  int _currentPoints = 0;
  int _pointsToNextLevel = 0;
  double _progress = 0.0;
  List<LevelInfo> _levels = [];
  Map<String, dynamic> _userData = {};
  
  @override
  void initState() {
    super.initState();
    _loadLevelsData();
  }
  
  Future<void> _loadLevelsData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get system levels configuration
      final levelsDoc = await _firestore.collection('system_settings').doc('levels').get();
      
      if (levelsDoc.exists) {
        final levelsData = levelsDoc.data() as Map<String, dynamic>;
        final levelsConfig = levelsData['levels'] as Map<String, dynamic>;
        
        List<LevelInfo> levels = [];
        
        // Convert to list of LevelInfo objects
        levelsConfig.forEach((key, value) {
          final levelData = value as Map<String, dynamic>;
          levels.add(LevelInfo(
            id: key,
            name: levelData['name'] ?? key,
            pointsRequired: (levelData['pointsRequired'] as num).toInt(),
            discountRate: (levelData['discountRate'] as num).toDouble(),
            benefits: List<String>.from(levelData['benefits'] ?? []),
            color: _getLevelColor(key),
          ));
        });
        
        // Sort levels by points required
        levels.sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));
        
        // Get user data
        final user = _auth.currentUser;
        if (user != null) {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final currentLevel = userData['level'] ?? 'bronze';
            final currentPoints = (userData['points'] as num?)?.toInt() ?? 0;
            
            // Calculate progress to next level
            int pointsToNextLevel = 0;
            double progress = 0.0;
            
            // Find current level index
            int currentLevelIndex = levels.indexWhere((level) => level.id == currentLevel);
            
            // If not the highest level, calculate progress to next level
            if (currentLevelIndex < levels.length - 1) {
              final nextLevel = levels[currentLevelIndex + 1];
              final currentLevelPoints = levels[currentLevelIndex].pointsRequired;
              
              pointsToNextLevel = nextLevel.pointsRequired - currentPoints;
              progress = (currentPoints - currentLevelPoints) / (nextLevel.pointsRequired - currentLevelPoints);
              progress = progress.clamp(0.0, 1.0);
            } else {
              // Highest level
              pointsToNextLevel = 0;
              progress = 1.0;
            }
            
            setState(() {
              _currentLevel = currentLevel;
              _currentPoints = currentPoints;
              _pointsToNextLevel = pointsToNextLevel;
              _progress = progress;
              _userData = userData;
            });
          }
        }
        
        setState(() {
          _levels = levels;
        });
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
  
  Color _getLevelColor(String level) {
    switch (level) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey.shade500;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
  
  String _getLevelName(String level) {
    switch (level) {
      case 'bronze':
        return 'برونزي';
      case 'silver':
        return 'فضي';
      case 'gold':
        return 'ذهبي';
      case 'platinum':
        return 'بلاتيني';
      default:
        return level;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام المستويات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current level card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // User info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: _getLevelColor(_currentLevel).withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: _getLevelColor(_currentLevel),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: _getLevelColor(_currentLevel),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getLevelName(_currentLevel),
                                          style: TextStyle(
                                            color: _getLevelColor(_currentLevel),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Points
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'النقاط الحالية:',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$_currentPoints نقطة',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Progress to next level
                          if (_pointsToNextLevel > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'النقاط المتبقية للمستوى التالي:',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '$_pointsToNextLevel نقطة',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Progress bar
                            LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(_currentLevel)),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_progress * 100).toInt()}% إلى المستوى التالي',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Text(
                              'لقد وصلت إلى أعلى مستوى!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // How to earn points
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'كيف تكسب النقاط؟',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPointsItem(
                            icon: Icons.swap_horiz,
                            title: 'إجراء المعاملات',
                            description: 'اكسب نقطة واحدة مقابل كل 10 دولار من المعاملات',
                          ),
                          _buildPointsItem(
                            icon: Icons.person_add,
                            title: 'دعوة الأصدقاء',
                            description: 'اكسب 50 نقطة لكل صديق يسجل باستخدام رمز الإحالة الخاص بك',
                          ),
                          _buildPointsItem(
                            icon: Icons.verified_user,
                            title: 'التحقق من الحساب',
                            description: 'اكسب 100 نقطة عند إكمال التحقق من هويتك',
                          ),
                          _buildPointsItem(
                            icon: Icons.star,
                            title: 'التقييمات الإيجابية',
                            description: 'اكسب 10 نقاط لكل تقييم إيجابي تحصل عليه',
                          ),
                          _buildPointsItem(
                            icon: Icons.calendar_month,
                            title: 'النشاط المنتظم',
                            description: 'اكسب 5 نقاط أسبوعياً عند إجراء معاملة واحدة على الأقل',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Levels list
                  const Text(
                    'المستويات والمزايا',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Levels cards
                  ..._levels.map((level) => _buildLevelCard(level)),
                ],
              ),
            ),
    );
  }
  
  Widget _buildPointsItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLevelCard(LevelInfo level) {
    final isCurrentLevel = level.id == _currentLevel;
    
    return Card(
      elevation: isCurrentLevel ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentLevel
            ? BorderSide(color: level.color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: level.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: level.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLevelName(level.id),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: level.color,
                        ),
                      ),
                      Text(
                        'يتطلب ${level.pointsRequired} نقطة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentLevel)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: level.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'المستوى الحالي',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'المزايا:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...level.benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(benefit),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.discount,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'خصم ${(level.discountRate * 100).toInt()}% على رسوم المعاملات',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
