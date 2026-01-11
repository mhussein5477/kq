import 'package:flutter/material.dart';
import 'package:kq/widgets/appBar.dart';

// Trends Screen

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trends',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildTotalContributionsCard(),
                    const SizedBox(height: 24),
                    _buildYearlyContributionsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Contributions',
          'KES 450,000',
          Icons.account_balance_wallet_outlined,
          const Color(0xFF6B7FED),
        ),
        _buildStatCard(
          'Employer Contributions',
          'KES 115,000',
          Icons.business_outlined,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'My Contributions',
          'KES 75,000',
          Icons.person_outline,
          const Color(0xFFFF6B6B),
        ),
        _buildStatCard(
          'Intrest',
          'KES 30,000',
          Icons.trending_up,
          const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalContributionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Contributions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'KES 450,000',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7FED),
            ),
          ),
          const Text(
            '6 Contributions',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CustomPaint(painter: DonutChartPainter()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      'Kenya Airways',
                      const Color(0xFF6B7FED),
                      '50%',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'United Nations',
                      const Color(0xFFFF6B9D),
                      '15%',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem('KRA', const Color(0xFFB24CFF), '35%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyContributionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Yearly Contributions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'This Year',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'KES 130,000',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE74C3C),
            ),
          ),
          const Text(
            '6 Contributions',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: CustomPaint(painter: LineChartPainter(), child: Container()),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Kenya Airways - 50% (180 degrees)
    paint.color = const Color(0xFF6B7FED);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -1.57, // Start at top (-90 degrees in radians)
      3.14, // 180 degrees
      false,
      paint,
    );

    // United Nations - 15% (54 degrees)
    paint.color = const Color(0xFFFF6B9D);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.57, // Start after Kenya Airways
      0.942, // 54 degrees
      false,
      paint,
    );

    // KRA - 35% (126 degrees)
    paint.color = const Color(0xFFB24CFF);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      2.512, // Start after United Nations
      2.198, // 126 degrees
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFA726)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Sample data points for the chart
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.75),
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.45, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.35),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width, size.height * 0.6),
    ];

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final controlPoint1 = Offset(
        current.dx + (next.dx - current.dx) / 3,
        current.dy,
      );
      final controlPoint2 = Offset(
        current.dx + 2 * (next.dx - current.dx) / 3,
        next.dy,
      );
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFFFFA726)
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw Y-axis labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final labels = ['60k', '20k'];
    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-35, size.height * (i == 0 ? 0.15 : 0.75)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
