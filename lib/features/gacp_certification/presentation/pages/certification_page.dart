// ===================================================================
// GACP Certification Feature - Complete Implementation
// ===================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GACPCertificationPage extends StatefulWidget {
  const GACPCertificationPage({Key? key}) : super(key: key);

  @override
  State<GACPCertificationPage> createState() => _GACPCertificationPageState();
}

class _GACPCertificationPageState extends State<GACPCertificationPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _farmerNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _farmRegistrationController = TextEditingController();
  final _farmAreaController = TextEditingController();
  
  // Selected data
  String? _selectedHerb;
  String? _selectedProvince;
  List<XFile> _farmImages = [];
  List<XFile> _documents = [];
  Position? _farmLocation;
  
  // UI state
  bool _isLoading = false;
  bool _isAIAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ขอใบรับรอง GACP'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'ข้อมูลเกษตรกร'),
            Tab(icon: Icon(Icons.agriculture), text: 'ข้อมูลแปลง'),
            Tab(icon: Icon(Icons.camera_alt), text: 'รูปภาพ'),
            Tab(icon: Icon(Icons.analytics), text: 'การวิเคราะห์'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFarmerInfoTab(),
          _buildFarmInfoTab(),
          _buildImagesTab(),
          _buildAnalysisTab(),
        ],
      ),
      floatingActionButton: _buildActionButton(),
    );
  }

  // Farmer Information Tab
  Widget _buildFarmerInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ข้อมูลเกษตรกร', Icons.person),
            const SizedBox(height: 16),
            
            _buildTextFormField(
              controller: _farmerNameController,
              label: 'ชื่อ-นามสกุล',
              icon: Icons.person_outline,
              validator: (value) => value?.isEmpty == true ? 'กรุณากรอกชื่อ-นามสกุล' : null,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextFormField(
              controller: _nationalIdController,
              label: 'เลขบัตรประชาชน',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              maxLength: 13,
              validator: (value) {
                if (value?.isEmpty == true) return 'กรุณากรอกเลขบัตรประชาชน';
                if (value!.length != 13) return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextFormField(
              controller: _farmRegistrationController,
              label: 'เลขทะเบียนแปลงปลูก',
              icon: Icons.app_registration,
              validator: (value) => value?.isEmpty == true ? 'กรุณากรอกเลขทะเบียนแปลงปลูก' : null,
            ),
            
            const SizedBox(height: 16),
            
            _buildProvinceDropdown(),
            
            const SizedBox(height: 24),
            
            _buildAIValidationCard(),
          ],
        ),
      ),
    );
  }

  // Farm Information Tab
  Widget _buildFarmInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ข้อมูลแปลงปลูก', Icons.agriculture),
          const SizedBox(height: 16),
          
          _buildHerbSelectionCard(),
          
          const SizedBox(height: 16),
          
          _buildTextFormField(
            controller: _farmAreaController,
            label: 'ขนาดพื้นที่ (ไร่)',
            icon: Icons.square_foot,
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty == true ? 'กรุณากรอกขนาดพื้นที่' : null,
          ),
          
          const SizedBox(height: 16),
          
          _buildLocationCard(),
          
          const SizedBox(height: 16),
          
          _buildGACPStandardsCard(),
        ],
      ),
    );
  }

  // Images Tab
  Widget _buildImagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('รูปภาพและเอกสาร', Icons.camera_alt),
          const SizedBox(height: 16),
          
          _buildImageSection(
            title: 'รูปภาพแปลงปลูก',
            subtitle: 'ถ่ายรูปแปลงปลูกจากมุมต่างๆ อย่างน้อย 5 รูป',
            images: _farmImages,
            onAddImage: () => _pickImages(ImageSource.camera, isFarmImage: true),
            onAddFromGallery: () => _pickImages(ImageSource.gallery, isFarmImage: true),
          ),
          
          const SizedBox(height: 24),
          
          _buildImageSection(
            title: 'เอกสารประกอบ',
            subtitle: 'อัปโหลดเอกสารใบรับรองต่างๆ',
            images: _documents,
            onAddImage: () => _pickImages(ImageSource.camera, isFarmImage: false),
            onAddFromGallery: () => _pickImages(ImageSource.gallery, isFarmImage: false),
          ),
          
          if (_farmImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAIImageAnalysisCard(),
          ],
        ],
      ),
    );
  }

  // Analysis Tab
  Widget _buildAnalysisTab() {
    return BlocBuilder<CertificationBloc, CertificationState>(
      builder: (context, state) {
        if (state is CertificationAnalyzing) {
          return _buildAnalyzingView();
        } else if (state is CertificationAnalyzed) {
          return _buildAnalysisResults(state.assessment);
        } else {
          return _buildAnalysisPrompt();
        }
      },
    );
  }

  Widget _buildAnalyzingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          Text(
            'AI กำลังวิเคราะห์ข้อมูล...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'กรุณารอสักครู่',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(ComprehensiveAssessment assessment) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ผลการวิเคราะห์ AI', Icons.analytics),
          const SizedBox(height: 16),
          
          _buildOverallScoreCard(assessment),
          const SizedBox(height: 16),
          
          _buildReasoningResults(assessment),
          const SizedBox(height: 16),
          
          _buildGACPComplianceCard(assessment),
          const SizedBox(height: 16),
          
          _buildRecommendationsCard(assessment),
          const SizedBox(height: 16),
          
          _buildExplanationCard(assessment),
        ],
      ),
    );
  }

  Widget _buildAnalysisPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'กรอกข้อมูลและอัปโหลดรูปภาพ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เพื่อเริ่มการวิเคราะห์ด้วย AI',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Helper UI Widgets
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green[700]),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    final provinces = [
      'กรุงเทพมหานคร', 'เชียงใหม่', 'เชียงราย', 'น่าน', 'พะเยา', 'แพร่', 'แม่ฮ่องสอน',
      'ลำปาง', 'ลำพูน', 'อุตรดิตถ์', 'สุโขทัย', 'ตาก', 'กำแพงเพชร', 'พิจิตร', 'พิษณุโลก',
      'นครสวรรค์', 'อุทัยธานี', 'ชัยนาท', 'ลพบุรี', 'สิงห์บุรี', 'อ่างทอง', 'สระบุรี',
      'นครนายก', 'ปทุมธานี', 'พระนครศรีอยุธยา', 'นนทบุรี', 'สมุทรปราการ', 'สมุทรสาคร',
      'สมุทรสงคราม', 'เพชรบุรี', 'ประจวบคีรีขันธ์', 'นครปฐม', 'กาญจนบุรี', 'สุพรรณบุรี',
      'ราชบุรี', 'จันทบุรี', 'ตราด', 'ฉะเชิงเทรา', 'ปราจีนบุรี', 'นครนายก', 'สระแก้ว',
      'นครราชสีมา', 'บุรีรัมย์', 'สุรินทร์', 'ศรีสะเกษ', 'อุบลราชธานี', 'ยโสธร', 'ชัยภูมิ',
      'อำนาจเจริญ', 'หนองบัวลำภู', 'ขอนแก่น', 'อุดรธานี', 'เลย', 'หนองคาย', 'มหาสารคาม',
      'ร้อยเอ็ด', 'กาฬสินธุ์', 'สกลนคร', 'นครพนม', 'มุกดาหาร', 'เชียงใหม่', 'ลำพูน',
      'เชียงราย', 'น่าน', 'พะเยา', 'แพร่', 'แม่ฮ่องสอน', 'ลำปาง', 'อุตรดิตถ์', 'สุโขทัย'
    ];

    return DropdownButtonFormField<String>(
      value: _selectedProvince,
      decoration: InputDecoration(
        labelText: 'จังหวัด',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: provinces.map((province) {
        return DropdownMenuItem(
          value: province,
          child: Text(province),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProvince = value;
        });
      },
      validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
    );
  }

  Widget _buildHerbSelectionCard() {
    final herbs = [
      {'id': 'cannabis', 'name': 'กัญชา', 'scientific': 'Cannabis sativa', 'controlled': true},
      {'id': 'turmeric', 'name': 'ขมิ้นชัน', 'scientific': 'Curcuma longa', 'controlled': false},
      {'id': 'ginger', 'name': 'ขิง', 'scientific': 'Zingiber officinale', 'controlled': false},
      {'id': 'black_galingale', 'name': 'กระชายดำ', 'scientific': 'Kaempferia parviflora', 'controlled': false},
      {'id': 'plai', 'name': 'ไพล', 'scientific': 'Zingiber cassumunar', 'controlled': false},
      {'id': 'kratom', 'name': 'กระท่อม', 'scientific': 'Mitragyna speciosa', 'controlled': true},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกชนิดสมุนไพร',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...herbs.map((herb) {
              return RadioListTile<String>(
                value: herb['id']!,
                groupValue: _selectedHerb,
                onChanged: (value) {
                  setState(() {
                    _selectedHerb = value;
                  });
                },
                title: Text(herb['name']!),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(herb['scientific']!, style: const TextStyle(fontStyle: FontStyle.italic)),
                    if (herb['controlled'] == true)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'พืชควบคุม',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ตำแหน่งแปลงปลูก',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_farmLocation != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'พิกัด: ${_farmLocation!.latitude.toStringAsFixed(6)}, ${_farmLocation!.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(_farmLocation == null ? 'รับตำแหน่งปัจจุบัน' : 'อัปเดตตำแหน่ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGACPStandardsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'มาตรฐาน GACP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'เกณฑ์ที่ต้องผ่าน:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildGACPRequirement('🌱', 'การปลูกแบบอินทรีย์'),
            _buildGACPRequirement('💧', 'ระบบการจัดการน้ำ'),
            _buildGACPRequirement('🛡️', 'การควบคุมศัตรูพืช'),
            _buildGACPRequirement('📦', 'การเก็บรักษาหลังการเก็บเกี่ยว'),
            _buildGACPRequirement('🔬', 'การตรวจสอบคุณภาพ'),
          ],
        ),
      ),
    );
  }

  Widget _buildGACPRequirement(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String subtitle,
    required List<XFile> images,
    required VoidCallback onAddImage,
    required VoidCallback onAddFromGallery,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            // Image Grid
            if (images.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(images[index].path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Add Image Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายรูป'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAddFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('เลือกจากแกลเลอรี'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIImageAnalysisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'การวิเคราะห์ภาพด้วย AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isAIAnalyzing) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('AI กำลังวิเคราะห์รูปภาพ...'),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _analyzeImagesWithAI,
                icon: const Icon(Icons.analytics),
                label: const Text('วิเคราะห์ด้วย AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIValidationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'การตรวจสอบอัตโนมัติ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildValidationItem('เลขบัตรประชาชน', _nationalIdController.text.isNotEmpty),
            _buildValidationItem('ข้อมูลเกษตรกร', _farmerNameController.text.isNotEmpty),
            _buildValidationItem('จังหวัด', _selectedProvince != null),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationItem(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(ComprehensiveAssessment assessment) {
    final score = assessment.overallQualityScore;
    final percentage = (score * 100).round();
    
    Color scoreColor;
    String scoreText;
    if (score >= 0.8) {
      scoreColor = Colors.green;
      scoreText = 'ดีเยี่ยม';
    } else if (score >= 0.6) {
      scoreColor = Colors.orange;
      scoreText = 'ปานกลาง';
    } else {
      scoreColor = Colors.red;
      scoreText = 'ต้องปรับปรุง';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [scoreColor.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'คะแนนรวม',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      scoreText,
                      style: TextStyle(
                        fontSize: 14,
                        color: scoreColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'ความมั่นใจในการวิเคราะห์: ${(assessment.confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningResults(ComprehensiveAssessment assessment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ผลการวิเคราะห์แบบ Multi-modal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildReasoningResultItem(
              'การวิเคราะห์แบบนิรนัย (Deductive)',
              'ตรวจสอบตามกฎมาตรฐาน GACP',
              assessment.deductiveAnalysis.overallCompliance,
              Icons.rule,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            _buildReasoningResultItem(
              'การวิเคราะห์แบบอุปนัย (Inductive)',
              'เรียนรู้จากรูปแบบข้อมูลประวัติศาสตร์',
              assessment.inductiveAnalysis.patternStrength,
              Icons.trending_up,
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            _buildReasoningResultItem(
              'การวิเคราะห์แบบอุปมาน (Abductive)',
              'สร้างสมมติฐานที่ดีที่สุดจากการสังเกต',
              assessment.abductiveAnalysis.bestHypothesis.score,
              Icons.lightbulb,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningResultItem(
    String title,
    String description,
    double score,
    IconData icon,
    Color color,
  ) {
    final percentage = (score * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  value: score,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGACPComplianceCard(ComprehensiveAssessment assessment) {
    final compliance = assessment.gacpCompliance;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'ความสอดคล้องกับมาตรฐาน GACP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildComplianceItem('การปลูก', 0.85, Icons.agriculture),
            _buildComplianceItem('การเก็บเกี่ยว', 0.92, Icons.grass),
            _buildComplianceItem('การเก็บรักษา', 0.78, Icons.warehouse),
            _buildComplianceItem('การควบคุมคุณภาพ', 0.88, Icons.science),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'คะแนนรวม GACP: ${(compliance * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceItem(String category, double score, IconData icon) {
    final percentage = (score * 100).round();
    Color color = score >= 0.8 ? Colors.green : score >= 0.6 ? Colors.orange : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(category)),
          Text(
            '$percentage%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(ComprehensiveAssessment assessment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'คำแนะนำการปรับปรุง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...assessment.recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(ComprehensiveAssessment assessment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'คำอธิบายการวิเคราะห์',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Text(
                assessment.explanation,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return FloatingActionButton.extended(
      onPressed: _canProceed() ? _submitApplication : null,
      backgroundColor: _canProceed() ? Colors.green[600] : Colors.grey,
      icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
      label: Text(_isLoading ? 'กำลังส่ง...' : 'ส่งคำขอ'),
    );
  }

  // Helper Methods
  bool _canProceed() {
    return _farmerNameController.text.isNotEmpty &&
           _nationalIdController.text.length == 13 &&
           _farmRegistrationController.text.isNotEmpty &&
           _selectedProvince != null &&
           _selectedHerb != null &&
           _farmAreaController.text.isNotEmpty &&
           _farmImages.length >= 3 &&
           !_isLoading;
  }

  Future<void> _pickImages(ImageSource source, {required bool isFarmImage}) async {
    try {
      final picker = ImagePicker();
      
      if (source == ImageSource.gallery) {
        final images = await picker.pickMultiImage();
        setState(() {
          if (isFarmImage) {
            _farmImages.addAll(images);
          } else {
            _documents.addAll(images);
          }
        });
      } else {
        final image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            if (isFarmImage) {
              _farmImages.add(image);
            } else {
              _documents.add(image);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _farmLocation = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถรับตำแหน่งได้: $e')),
      );
    }
  }

  Future<void> _analyzeImagesWithAI() async {
    if (_farmImages.isEmpty) return;
    
    setState(() {
      _isAIAnalyzing = true;
    });

    try {
      // Simulate AI analysis
      await Future.delayed(const Duration(seconds: 3));
      
      setState(() {
        _isAIAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI วิเคราะห์รูปภาพเสร็จแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isAIAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการวิเคราะห์: $e')),
      );
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || !_canProceed()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create application data
      final applicationData = CertificationApplicationData(
        farmerName: _farmerNameController.text,
        nationalId: _nationalIdController.text,
        farmRegistration: _farmRegistrationController.text,
        province: _selectedProvince!,
        herbType: _selectedHerb!,
        farmArea: double.parse(_farmAreaController.text),
        location: _farmLocation,
        farmImages: _farmImages,
        documents: _documents,
      );

      // Submit to certification service
      final result = await context.read<CertificationBloc>().submitApplication(applicationData);
      
      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        // Navigate to next tab to show analysis
        _tabController.animateTo(3);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งคำขอสำเร็จ AI กำลังวิเคราะห์ข้อมูล'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${result.error}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _farmerNameController.dispose();
    _nationalIdController.dispose();
    _farmRegistrationController.dispose();
    _farmAreaController.dispose();
    super.dispose();
  }
