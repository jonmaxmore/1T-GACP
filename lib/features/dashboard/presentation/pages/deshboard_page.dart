// ===================================================================
// Dashboard Feature - Complete Implementation
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Mock data
  final int totalApplications = 1247;
  final int approvedApplications = 856;
  final int pendingApplications = 234;
  final int rejectedApplications = 157;
  final int activeTrackings = 1892;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ด Thai Herbal GACP'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showNotifications();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              
              _buildQuickStats(),
              const SizedBox(height: 24),
              
              _buildRecentActivity(),
              const SizedBox(height: 24),
              
              _buildCertificationChart(),
              const SizedBox(height: 24),
              
              _buildHerbPopularityChart(),
              const SizedBox(height: 24),
              
              _buildQuickActions(),
              const SizedBox(height: 24),
              
              _buildSystemStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'สวัสดีตอนเช้า';
    } else if (hour < 17) {
      greeting = 'สวัสดีตอนบ่าย';
    } else {
      greeting = 'สวัสดีตอนเย็น';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ยินดีต้อนรับสู่ระบบ GACP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ระบบ AI กำลังทำงานปกติ • การเรียนรู้อัตโนมัติ: เปิดใช้งาน',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {
        'title': 'คำขอทั้งหมด',
        'value': totalApplications.toString(),
        'icon': Icons.description,
        'color': Colors.blue,
        'trend': '+12%',
        'isPositive': true,
      },
      {
        'title': 'อนุมัติแล้ว',
        'value': approvedApplications.toString(),
        'icon': Icons.check_circle,
        'color': Colors.green,
        'trend': '+8%',
        'isPositive': true,
      },
      {
        'title': 'รอการอนุมัติ',
        'value': pendingApplications.toString(),
        'icon': Icons.pending,
        'color': Colors.orange,
        'trend': '-3%',
        'isPositive': false,
      },
      {
        'title': 'ติดตามสินค้า',
        'value': activeTrackings.toString(),
        'icon': Icons.track_changes,
        'color': Colors.purple,
        'trend': '+15%',
        'isPositive': true,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 24,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (stat['isPositive'] as bool) 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stat['trend'] as String,
                        style: TextStyle(
                          color: (stat['isPositive'] as bool) ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {
        'title': 'คำขอใบรับรอง GACP ใหม่',
        'subtitle': 'ฟาร์มสมุนไพรไทย - กัญชาทางการแพทย์',
        'time': '10 นาทีที่แล้ว',
        'icon': Icons.add_circle,
        'color': Colors.green,
      },
      {
        'title': 'AI วิเคราะห์เสร็จสิ้น',
        'subtitle': 'คำขอ #TH-2024-001234 - คะแนน 89%',
        'time': '25 นาทีที่แล้ว',
        'icon': Icons.analytics,
        'color': Colors.blue,
      },
      {
        'title': 'อัพเดตการติดตาม',
        'subtitle': 'ขมิ้นชันอินทรีย์ - ถึงจุดหมายแล้ว',
        'time': '1 ชั่วโมงที่แล้ว',
        'icon': Icons.location_on,
        'color': Colors.orange,
      },
      {
        'title': 'ระบบเรียนรู้อัตโนมัติ',
        'subtitle': 'โมเดล AI ได้รับการปรับปรุงแล้ว',
        'time': '2 ชั่วโมงที่แล้ว',
        'icon': Icons.school,
        'color': Colors.purple,
      },
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'กิจกรรมล่าสุด',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity log
                  },
                  child: const Text('ดูทั้งหมด'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...activities.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    activity['time'] as String,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สถานะการขอใบรับรอง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: approvedApplications.toDouble(),
                      title: 'อนุมัติ\n${((approvedApplications / totalApplications) * 100).round()}%',
                      color: Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: pendingApplications.toDouble(),
                      title: 'รอดำเนินการ\n${((pendingApplications / totalApplications) * 100).round()}%',
                      color: Colors.orange,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: rejectedApplications.toDouble(),
                      title: 'ปฏิเสธ\n${((rejectedApplications / totalApplications) * 100).round()}%',
                      color: Colors.red,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('อนุมัติ', Colors.green, approvedApplications),
                _buildLegendItem('รอดำเนินการ', Colors.orange, pendingApplications),
                _buildLegendItem('ปฏิเสธ', Colors.red, rejectedApplications),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHerbPopularityChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ความนิยมของสมุนไพร',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
