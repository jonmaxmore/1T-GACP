// ===================================================================
// Knowledge Graph Feature - Complete Implementation
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

class KnowledgeGraphPage extends StatefulWidget {
  const KnowledgeGraphPage({Key? key}) : super(key: key);

  @override
  State<KnowledgeGraphPage> createState() => _KnowledgeGraphPageState();
}

class _KnowledgeGraphPageState extends State<KnowledgeGraphPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  // State
  bool _isSearching = false;
  List<HerbKnowledge> _searchResults = [];
  List<HerbRecommendation> _recommendations = [];
  String? _selectedCondition;

  // Mock herb data
  final List<HerbKnowledge> _allHerbs = [
    HerbKnowledge(
      id: 'cannabis_sativa',
      thaiName: 'กัญชา',
      scientificName: 'Cannabis sativa L.',
      family: 'Cannabaceae',
      description: 'พืชสมุนไพรที่มีสารสำคัญ THC และ CBD ใช้ในการรักษาโรคต่างๆ',
      properties: [
        HerbProperty(name: 'THC', type: 'cannabinoid', concentration: '0.2-30%'),
        HerbProperty(name: 'CBD', type: 'cannabinoid', concentration: '0.1-25%'),
        HerbProperty(name: 'Terpenes', type: 'volatile_compounds', concentration: '1-3%'),
      ],
      medicalUses: [
        MedicalUse(condition: 'โรคลมชัก', effectiveness: 0.85, evidence: 'การทดลองทางคลินิก'),
        MedicalUse(condition: 'ปวดเรื้อรัง', effectiveness: 0.78, evidence: 'การวิเคราะห์เมตา'),
        MedicalUse(condition: 'คลื่นไส้จากเคมีบำบัด', effectiveness: 0.82, evidence: 'การศึกษาแบบ RCT'),
      ],
      contraindications: ['ตั้งครรภ์', 'ให้นมบุตร', 'โรคหัวใจรุนแรง'],
      interactions: ['วาร์ฟาริน', 'ยาระงับประสาท', 'แอลกอฮอล์'],
      imageUrl: 'assets/images/cannabis.jpg',
    ),
    HerbKnowledge(
      id: 'curcuma_longa',
      thaiName: 'ขมิ้นชัน',
      scientificName: 'Curcuma longa L.',
      family: 'Zingiberaceae',
      description: 'สมุนไพรที่มีสารเคอร์คิวมิน มีคุณสมบัติต้านการอักเสบและต้านอนุมูลอิสระ',
      properties: [
        HerbProperty(name: 'Curcumin', type: 'polyphenol', concentration: '2-8%'),
        HerbProperty(name: 'น้ำมันหอมระเหย', type: 'essential_oils', concentration: '3-7%'),
        HerbProperty(name: 'แป้ง', type: 'carbohydrate', concentration: '25-30%'),
      ],
      medicalUses: [
        MedicalUse(condition: 'อักเสบ', effectiveness: 0.76, evidence: 'การทบทวนอย่างเป็นระบบ'),
        MedicalUse(condition: 'ข้ออักเสบ', effectiveness: 0.68, evidence: 'การทดลองทางคลินิก'),
        MedicalUse(condition: 'โรคทางเดินอาหาร', effectiveness: 0.72, evidence: 'การใช้แบบดั้งเดิม'),
      ],
      contraindications: ['นิ่วในถุงน้ำดี', 'โรคเลือดไม่แข็งตัว', 'โรคกรดไหลย้อน'],
      interactions: ['ยาต้านการแข็งตัวของเลือด', 'ยาเบาหวาน', 'ยาเคมีบำบัด'],
      imageUrl: 'assets/images/turmeric.jpg',
    ),
    HerbKnowledge(
      id: 'zingiber_officinale',
      thaiName: 'ขิง',
      scientificName: 'Zingiber officinale Rosc.',
      family: 'Zingiberaceae',
      description: 'สมุนไพรที่มีสารจินเจอรอล ใช้รักษาอาการคลื่นไส้และปวดท้อง',
      properties: [
        HerbProperty(name: 'Gingerol', type: 'phenolic_compound', concentration: '1-3%'),
        HerbProperty(name: 'Shogaol', type: 'phenolic_compound', concentration: '0.5-1%'),
        HerbProperty(name: 'น้ำมันหอมระเหย', type: 'volatile_compounds', concentration: '1-4%'),
      ],
      medicalUses: [
        MedicalUse(condition: 'คลื่นไส้', effectiveness: 0.89, evidence: 'การทบทวน Cochrane'),
        MedicalUse(condition: 'เมารถเมาเรือ', effectiveness: 0.82, evidence: 'การศึกษาแบบ RCT'),
        MedicalUse(condition: 'อาการแพ้ท้องเช้า', effectiveness: 0.76, evidence: 'การทดลองทางคลินิก'),
      ],
      contraindications: ['นิ่วในถุงน้ำดี', 'โรคเลือดไม่แข็งตัว', 'ความดันโลหิตสูง'],
      interactions: ['ยาต้านการแข็งตัวของเลือด', 'ยาเบาหวาน', 'ยาหัวใจ'],
      imageUrl: 'assets/images/ginger.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchResults = _allHerbs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ฐานความรู้สมุนไพร'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'ค้นหา'),
            Tab(icon: Icon(Icons.local_pharmacy), text: 'สมุนไพร'),
            Tab(icon: Icon(Icons.medical_services), text: 'การใช้งาน'),
            Tab(icon: Icon(Icons.analytics), text: 'สถิติ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildHerbsTab(),
          _buildMedicalUsesTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ค้นหาความรู้', Icons.search),
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'ค้นหาสมุนไพร โรค หรือสารสำคัญ',
              hintText: 'เช่น กัญชา, ปวดหัว, CBD',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _performSearch,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Search Categories
          _buildQuickSearchCategories(),
          
          const SizedBox(height: 24),
          
          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildHerbsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('สมุนไพรทั้งหมด', Icons.local_pharmacy),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: _allHerbs.length,
              itemBuilder: (context, index) {
                return _buildHerbCard(_allHerbs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalUsesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('การใช้งานทางการแพทย์', Icons.medical_services),
          const SizedBox(height: 16),
          
          // Condition Selector
          _buildConditionSelector(),
          
          const SizedBox(height: 16),
          
          // Recommendations
          if (_recommendations.isNotEmpty) ...[
            const Text(
              'สมุนไพรที่แนะนำ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  return _buildRecommendationCard(_recommendations[index]);
                },
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medical_services, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'เลือกอาการเพื่อดูคำแนะนำ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('สถิติฐานความรู้', Icons.analytics),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatsOverviewCards(),
                  const SizedBox(height: 24),
                  
                  _buildFamilyDistributionChart(),
                  const SizedBox(height: 24),
                  
                  _buildEffectivenessChart(),
                  const SizedBox(height: 24),
                  
                  _buildInteractionNetworkCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.teal[700]),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSearchCategories() {
    final categories = [
      {'name': 'ต้านการอักเสบ', 'icon': Icons.healing, 'color': Colors.red},
      {'name': 'ปวดหัว', 'icon': Icons.psychology, 'color': Colors.blue},
      {'name': 'ระบบย่อยอาหาร', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'ความดันโลหิต', 'icon': Icons.favorite, 'color': Colors.pink},
      {'name': 'เบาหวาน', 'icon': Icons.bloodtype, 'color': Colors.purple},
      {'name': 'ต้านมะเร็ง', 'icon': Icons.shield, 'color': Colors.green},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'หมวดหมู่ยอดนิยม',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ElevatedButton.icon(
              onPressed: () => _searchByCategory(category['name'] as String),
              icon: Icon(category['icon'] as IconData),
              label: Text(category['name'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: (category['color'] as Color).withOpacity(0.1),
                foregroundColor: category['color'] as Color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'ไม่พบผลการค้นหา',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ลองค้นหาด้วยคำอื่น',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildHerbCard(_searchResults[index]);
      },
    );
  }

  Widget _buildHerbCard(HerbKnowledge herb) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showHerbDetails(herb),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.teal[100],
                    ),
                    child: Icon(
                      Icons.local_pharmacy,
                      color: Colors.teal[600],
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          herb.thaiName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          herb.scientificName,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'วงศ์: ${herb.family}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                herb.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Medical Uses Tags
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: herb.medicalUses.take(3).map((use) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      use.condition,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionSelector() {
    final conditions = [
      'ปวดหัว', 'อักเสบ', 'คลื่นไส้', 'ปวดเรื้อรัง', 'ข้ออักเสบ',
      'โรคลมชัก', 'เบาหวาน', 'ความดันโลหิตสูง', 'โรคหัวใจ'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เลือกอาการหรือโรค',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _selectedCondition,
          decoration: InputDecoration(
            labelText: 'อาการ/โรค',
            prefixIcon: const Icon(Icons.medical_services),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: conditions.map((condition) {
            return DropdownMenuItem(
              value: condition,
              child: Text(condition),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCondition = value;
            });
            if (value != null) {
              _getRecommendationsForCondition(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(HerbRecommendation recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recommendation.herbName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEffectivenessColor(recommendation.effectiveness),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(recommendation.effectiveness * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: recommendation.effectiveness,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getEffectivenessColor(recommendation.effectiveness),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'หลักฐาน: ${recommendation.evidence}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            if (recommendation.contraindications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ข้อห้าม: ${recommendation.contraindications.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverviewCards() {
    final stats = [
      {'title': 'สมุนไพรทั้งหมด', 'value': '6', 'icon': Icons.local_pharmacy, 'color': Colors.blue},
      {'title': 'การใช้งานทางการแพทย์', 'value': '18', 'icon': Icons.medical_services, 'color': Colors.green},
      {'title': 'สารสำคัญ', 'value': '24', 'icon': Icons.science, 'color': Colors.orange},
      {'title': 'ปฏิสัมพันธ์', 'value': '42', 'icon': Icons.warning, 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFamilyDistributionChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'การกระจายตามวงศ์พืช',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 4,
                      title: 'Zingiberaceae\n67%',
                      color: Colors.blue,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: 1,
                      title: 'Cannabaceae\n17%',
                      color: Colors.green,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: 1,
                      title: 'Rubiaceae\n17%',
                      color: Colors.orange,
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 0,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectivenessChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ประสิทธิภาพการรักษา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 89, color: Colors.blue)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 85, color: Colors.green)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 82, color: Colors.orange)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 78, color: Colors.red)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 76, color: Colors.purple)]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final conditions = ['คลื่นไส้', 'ลมชัก', 'เคมีบำบัด', 'ปวดเรื้อรัง', 'อักเสบ'];
                          return Text(
                            conditions[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionNetworkCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เครือข่ายความสัมพันธ์',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.device_hub, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'แผนภาพเครือข่ายความสัมพันธ์',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'ระหว่างสมุนไพรและการใช้งาน',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNetworkStat('โหนด', '48', Colors.blue),
                _buildNetworkStat('ความสัมพันธ์', '126', Colors.green),
                _buildNetworkStat('คลัสเตอร์', '6', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Helper Methods
  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Simulate search
      await Future.delayed(const Duration(seconds: 1));
      
      final results = _allHerbs.where((herb) {
        final searchQuery = query.toLowerCase();
        return herb.thaiName.toLowerCase().contains(searchQuery) ||
               herb.scientificName.toLowerCase().contains(searchQuery) ||
               herb.description.toLowerCase().contains(searchQuery) ||
               herb.medicalUses.any((use) => use.condition.toLowerCase().contains(searchQuery)) ||
               herb.properties.any((prop) => prop.name.toLowerCase().contains(searchQuery));
      }).toList();
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _searchByCategory(String category) {
    _searchController.text = category;
    _performSearch();
  }

  void _showHerbDetails(HerbKnowledge herb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Header
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.teal[100],
                      ),
                      child: Icon(
                        Icons.local_pharmacy,
                        color: Colors.teal[600],
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            herb.thaiName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            herb.scientificName,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'วงศ์: ${herb.family}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Description
                _buildDetailSection('คำอธิบาย', herb.description),
                
                const SizedBox(height: 20),
                
                // Properties
                _buildDetailSection(
                  'สารสำคัญ',
                  herb.properties.map((p) => '• ${p.name} (${p.type}): ${p.concentration}').join('\n'),
                ),
                
                const SizedBox(height: 20),
                
                // Medical Uses
                const Text(
                  'การใช้งานทางการแพทย์',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                ...herb.medicalUses.map((use) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                use.condition,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getEffectivenessColor(use.effectiveness),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(use.effectiveness * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'หลักฐาน: ${use.evidence}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
                
                const SizedBox(height: 20),
                
                // Contraindications
                if (herb.contraindications.isNotEmpty) ...[
                  _buildWarningSection('ข้อห้าม', herb.contraindications),
                  const SizedBox(height: 16),
                ],
                
                // Interactions
                if (herb.interactions.isNotEmpty) ...[
                  _buildWarningSection('ปฏิสัมพันธ์กับยา', herb.interactions),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildWarningSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $item',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _getRecommendationsForCondition(String condition) async {
    setState(() {
      _recommendations = [];
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final recommendations = <HerbRecommendation>[];
    
    for (final herb in _allHerbs) {
      final relevantUses = herb.medicalUses
          .where((use) => use.condition.toLowerCase().contains(condition.toLowerCase()))
          .toList();
      
      if (relevantUses.isNotEmpty) {
        final avgEffectiveness = relevantUses
            .map((use) => use.effectiveness)
            .reduce((a, b) => a + b) / relevantUses.length;
        
        recommendations.add(HerbRecommendation(
          herbId: herb.id,
          herbName: herb.thaiName,
          effectiveness: avgEffectiveness,
          evidence: relevantUses.first.evidence,
          contraindications: herb.contraindications,
          interactions: herb.interactions,
        ));
      }
    }
    
    // Sort by effectiveness
    recommendations.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
    
    setState(() {
      _recommendations = recommendations;
    });
  }

  Color _getEffectivenessColor(double effectiveness) {
    if (effectiveness >= 0.8) return Colors.green;
    if (effectiveness >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Data Models
class HerbKnowledge {
  final String id;
  final String thaiName;
  final String scientificName;
  final String family;
  final String description;
  final List<HerbProperty> properties;
  final List<MedicalUse> medicalUses;
  final List<String> contraindications;
  final List<String> interactions;
  final String imageUrl;

  HerbKnowledge({
    required this.id,
    required this.thaiName,
    required this.scientificName,
    required this.family,
    required this.description,
    required this.properties,
    required this.medicalUses,
    required this.contraindications,
    required this.interactions,
    required this.imageUrl,
  });
}

class HerbProperty {
  final String name;
  final String type;
  final String concentration;

  HerbProperty({
    required this.name,
    required this.type,
    required this.concentration,
  });
}

class MedicalUse {
  final String condition;
  final double effectiveness;
  final String evidence;

  MedicalUse({
    required this.condition,
    required this.effectiveness,
    required this.evidence,
  });
}

class HerbRecommendation {
  final String herbId;
  final String herbName;
  final double effectiveness;
  final String evidence;
  final List<String> contraindications;
  final List<String> interactions;

  HerbRecommendation({
    required this.herbId,
    required this.herbName,
    required this.effectiveness,
    required this.evidence,
    required this.contraindications,
    required this.interactions,
  });
}
