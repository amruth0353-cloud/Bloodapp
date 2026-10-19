import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  static const _articles = [
    _Article(
      icon: Icons.favorite_border,
      title: 'Who Can Donate Blood?',
      summary: 'Basic eligibility requirements for blood donation.',
      color: Color(0xFFCC1F2D),
    ),
    _Article(
      icon: Icons.restaurant_menu,
      title: 'What to Eat Before Donating',
      summary: 'Prepare your body for a successful donation.',
      color: Color(0xFFF57C00),
    ),
    _Article(
      icon: Icons.medical_services_outlined,
      title: 'The Donation Process',
      summary: 'Step-by-step guide to your donation visit.',
      color: Color(0xFF1565C0),
    ),
    _Article(
      icon: Icons.healing_outlined,
      title: 'Post-Donation Care',
      summary: 'How to recover well after donating.',
      color: Color(0xFF2E7D32),
    ),
    _Article(
      icon: Icons.science_outlined,
      title: 'Blood Type Compatibility',
      summary: 'Understanding who can give and receive blood.',
      color: Color(0xFF9C27B0),
    ),
    _Article(
      icon: Icons.info_outline,
      title: 'Why Blood Donation Matters',
      summary: 'The impact of your donation on patients.',
      color: Color(0xFFD84315),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloodConnectAppBar(title: 'Learn About Donation'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (ctx, i) {
          final a = _articles[i];
          return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => _ArticleDetailScreen(article: a),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: a.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a.icon, color: a.color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                a.summary,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: i * 60))
              .slideX(begin: 0.05);
        },
      ),
    );
  }
}

class _Article {
  final IconData icon;
  final String title;
  final String summary;
  final Color color;
  const _Article({
    required this.icon,
    required this.title,
    required this.summary,
    required this.color,
  });
}

class _ArticleDetailScreen extends StatelessWidget {
  final _Article article;
  const _ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: article.color,
        foregroundColor: Colors.white,
        title: Text(
          article.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: article.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: article.color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(article.icon, color: article.color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      article.summary,
                      style: TextStyle(
                        color: article.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getContent(article.title),
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getContent(String title) {
    switch (title) {
      case 'Who Can Donate Blood?':
        return 'To donate blood you must be 17-65 years old and weigh at least 50kg. Your hemoglobin must be at least 12.5 g/dL. You should not have donated in the last 56 days. You must be generally healthy with no active illness.\n\nDo NOT donate if you have had a fever in the last 7 days, recently had a tattoo or piercing, are pregnant or breastfeeding, or have recently had surgery.';
      case 'What to Eat Before Donating':
        return 'Eat iron-rich foods 24 hours before: red meat, chicken, fish, spinach, beans, and fortified cereals. Drink 500ml extra water the day before. Avoid alcohol for 24 hours and do not skip meals.\n\nOn donation day, eat a light meal 2-3 hours before and keep drinking water.';
      case 'The Donation Process':
        return 'Step 1 - Registration (5 min): Check in and complete health questionnaire.\n\nStep 2 - Health Screening (10 min): Blood pressure, pulse, and hemoglobin check.\n\nStep 3 - Donation (8-10 min): About 450ml of blood is collected.\n\nStep 4 - Recovery (10-15 min): Rest and have refreshments.\n\nTotal time: 30-45 minutes.';
      case 'Post-Donation Care':
        return 'After donating: rest for 15 minutes before leaving, drink extra fluids for 48 hours, eat iron-rich foods, keep the bandage on for 4 hours.\n\nAvoid for 24 hours: heavy lifting, alcohol, and strenuous exercise.\n\nIf you feel dizzy, sit or lie down immediately and raise your feet.';
      case 'Blood Type Compatibility':
        return 'O- is the universal donor - can donate to everyone.\nAB+ is the universal recipient - can receive from everyone.\nO+ can donate to A+, B+, AB+, and O+.\nA+ can donate to A+ and AB+.\nB+ can donate to B+ and AB+.\nAB+ can only donate to AB+.\n\nYour blood type is determined by genetics and never changes.';
      default:
        return 'Every blood donation can save up to 3 lives. Blood cannot be manufactured artificially, so donations are always needed.\n\nYour donation helps accident victims, surgery patients, cancer patients, and newborns with complications.\n\nBlood banks need constant replenishment because platelets only last 5-7 days and red blood cells last 42 days.';
    }
  }
}
