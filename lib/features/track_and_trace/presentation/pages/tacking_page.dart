// ===================================================================
// Track & Trace Feature - Complete Implementation
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class TrackAndTracePage extends StatefulWidget {
  const TrackAndTracePage({Key? key}) : super(key: key);

  @override
  State<TrackAndTracePage> createState() => _TrackAndTracePageState();
}

class _TrackAndTracePageState extends State<TrackAndTracePage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  // State
  bool _isScanning = false;
  bool _isSearching = false;
  TrackingResult? _currentTrackingResult;
  QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track & Trace'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'สแกน QR'),
            Tab(icon: Icon(Icons.search), text: 'ค้นหา'),
            Tab(icon: Icon(Icons.timeline), text: 'ประวัติ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRScannerTab(),
          _buildSearchTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildQRScannerTab() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[300]!, width: 2),
            ),
            child: _isScanning
                ? _buildScannerView()
                : _buildScannerPrompt(),
          ),
        ),
        
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleScanner,
                  icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                  label: Text(_isScanning ? 'หยุดสแกน' : 'เริ่มสแกน QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (_currentTrackingResult != null) ...[
                  _buildQuickTrackingInfo(_currentTrackingResult!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: QRView(
        key: _qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.purple[400]!,
          borderRadius: 12,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }

  Widget _buildScannerPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'สแกน QR Code เพื่อติดตามสินค้า',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม "เริ่มสแกน" เพื่อเปิดกล้อง',
            style: TextStyle(color: Colors.grey[500]),
          ),
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
          _buildSectionHeader('ค้นหาสินค้า', Icons.search),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'รหัสติดตาม หรือ QR Code',
              hintText: 'TH-HERB-2024-001234',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _searchProduct,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onSubmitted: (_) => _searchProduct(),
          ),
          
          const SizedBox(height: 24),
          
          _buildQuickSearchOptions(),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: _currentTrackingResult != null 
                ? _buildTrackingResult(_currentTrackingResult!)
                : _buildSearchPrompt(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ประวัติการติดตาม', Icons.history),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Mock data
              itemBuilder: (context, index) {
                return _buildHistoryItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchOptions() {
    final options = [
      {'label': 'กัญชา', 'icon': Icons.eco, 'color': Colors.green},
      {'label': 'ขมิ้นชัน', 'icon': Icons.spa, 'color': Colors.orange},
      {'label': 'ขิง', 'icon': Icons.local_florist, 'color': Colors.amber},
      {'label': 'ไพล', 'icon': Icons.healing, 'color': Colors.blue},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ค้นหาแบบด่วน',
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
          itemCount: options.length,
          itemBuilder: (context, index) {
            final option = options[index];
            return ElevatedButton.icon(
              onPressed: () => _quickSearch(option['label'] as String),
              icon: Icon(option['icon'] as IconData),
              label: Text(option['label'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: (option['color'] as Color).withOpacity(0.1),
                foregroundColor: option['color'] as Color,
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

  Widget _buildQuickTrackingInfo(TrackingResult result) {
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
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'ข้อมูลสินค้า',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text('ชื่อสินค้า: ${result.productName}'),
            Text('สถานะ: ${result.currentStatus}'),
            Text('ตำแหน่งปัจจุบัน: ${result.currentLocation}'),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _viewFullTrackingDetails(result),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('ดูรายละเอียดทั้งหมด'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingResult(TrackingResult result) {
    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductHeader(result),
              const SizedBox(height: 16),
              
              _buildTrackingTimeline(result),
              const SizedBox(height: 16),
              
              _buildCurrentStatus(result),
              const SizedBox(height: 16),
              
              _buildActionButtons(result),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(TrackingResult result) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.green[100],
          ),
          child: Icon(
            Icons.eco,
            color: Colors.green[600],
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.productName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'รหัส: ${result.trackingId}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                'ผลิตโดย: ${result.producer}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(result.currentStatus).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            result.currentStatus,
            style: TextStyle(
              color: _getStatusColor(result.currentStatus),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTimeline(TrackingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ประวัติการเดินทาง',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        ...result.timeline.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final isLast = index == result.timeline.length - 1;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: event.isComplete ? Colors.green : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: event.isComplete
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDateTime(event.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                    if (!isLast) const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCurrentStatus(TrackingResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'ตำแหน่งปัจจุบัน',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text('📍 ${result.currentLocation}'),
          Text('🕐 อัปเดตล่าสุด: ${result.lastUpdate}'),
          Text('🚛 สถานะ: ${result.currentStatus}'),
          
          if (result.estimatedArrival != null) ...[
            const SizedBox(height: 8),
            Text('⏰ คาดหมายถึงจุดหมาย: ${result.estimatedArrival}'),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(TrackingResult result) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareTracking(result),
            icon: const Icon(Icons.share),
            label: const Text('แชร์'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _downloadReport(result),
            icon: const Icon(Icons.download),
            label: const Text('ดาวน์โหลดรายงาน'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ใส่รหัสติดตามเพื่อค้นหาสินค้า',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'หรือเลือกจากตัวเลือกด่วนด้านบน',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(int index) {
    // Mock history data
    final histories = [
      {
        'product': 'ขมิ้นชันอินทรีย์',
        'trackingId': 'TH-HERB-2024-00123$index',
        'date': '15 มิ.ย. 2567',
        'status': 'จัดส่งสำเร็จ',
        'icon': Icons.spa,
        'color': Colors.orange,
      },
      {
        'product': 'กัญชาทางการแพทย์',
        'trackingId': 'TH-HERB-2024-00124$index',
        'date': '14 มิ.ย. 2567',
        'status': 'กำลังขนส่ง',
        'icon': Icons.eco,
        'color': Colors.green,
      },
    ];
    
    final history = histories[index % histories.length];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (history['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            history['icon'] as IconData,
            color: history['color'] as Color,
          ),
        ),
        title: Text(
          history['product'] as String,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รหัส: ${history['trackingId']}'),
            Text('วันที่: ${history['date']}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(history['status'] as String).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            history['status'] as String,
            style: TextStyle(
              color: _getStatusColor(history['status'] as String),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () => _viewHistoryDetails(history['trackingId'] as String),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.purple[700]),
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

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'จัดส่งสำเร็จ':
      case 'สำเร็จ':
        return Colors.green;
      case 'กำลังขนส่ง':
      case 'ระหว่างการขนส่ง':
        return Colors.blue;
      case 'รอจัดส่ง':
      case 'เตรียมสินค้า':
        return Colors.orange;
      case 'ยกเลิก':
      case 'มีปัญหา':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      _onQRCodeDetected(scanData.code ?? '');
    });
  }

  void _toggleScanner() async {
    if (_isScanning) {
      setState(() {
        _isScanning = false;
      });
      _qrController?.dispose();
    } else {
      final permission = await Permission.camera.request();
      if (permission.isGranted) {
        setState(() {
          _isScanning = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตให้เข้าถึงกล้อง')),
        );
      }
    }
  }

  void _onQRCodeDetected(String qrData) {
    setState(() {
      _isScanning = false;
    });
    
    _searchController.text = qrData;
    _searchProduct();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('พบ QR Code: $qrData'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _searchProduct() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock tracking result
      final result = TrackingResult(
        trackingId: query,
        productName: 'ขมิ้นชันอินทรีย์ เกรด A',
        producer: 'ฟาร์มสมุนไพรไทย',
        currentStatus: 'กำลังขนส่ง',
        currentLocation: 'ศูนย์กระจายสินค้า กรุงเทพ',
        lastUpdate: DateTime.now().toString().substring(0, 16),
        estimatedArrival: 'วันพรุ่งนี้ 14:00 น.',
        timeline: [
          TrackingEvent(
            title: 'เก็บเกี่ยว',
            description: 'เก็บเกี่ยวจากแปลงปลูกอินทรีย์',
            timestamp: DateTime.now().subtract(const Duration(days: 5)),
            isComplete: true,
          ),
          TrackingEvent(
            title: 'ตรวจสอบคุณภาพ',
            description: 'ผ่านการตรวจสอบมาตรฐาน GACP',
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
            isComplete: true,
          ),
          TrackingEvent(
            title: 'บรรจุภัณฑ์',
            description: 'บรรจุและติดฉลาก QR Code',
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
            isComplete: true,
          ),
          TrackingEvent(
            title: 'ขนส่ง',
            description: 'เริ่มการขนส่งสู่จุดหมาย',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isComplete: true,
          ),
          TrackingEvent(
            title: 'จัดส่ง',
            description: 'จัดส่งถึงลูกค้า',
            timestamp: DateTime.now().add(const Duration(days: 1)),
            isComplete: false,
          ),
        ],
      );
      
      setState(() {
        _currentTrackingResult = result;
        _isSearching = false;
      });
      
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบข้อมูล: $e')),
      );
    }
  }

  void _quickSearch(String herbType) {
    // Generate mock tracking ID for quick search
    final trackingId = 'TH-${herbType.toUpperCase()}-2024-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _searchController.text = trackingId;
    _searchProduct();
  }

  void _viewFullTrackingDetails(TrackingResult result) {
    // Navigate to detailed tracking page or show bottom sheet
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
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'รายละเอียดการติดตาม',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildTrackingResult(result),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareTracking(TrackingResult result) {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กำลังแชร์ข้อมูลการติดตาม...')),
    );
  }

  void _downloadReport(TrackingResult result) {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กำลังดาวน์โหลดรายงาน...')),
    );
  }

  void _viewHistoryDetails(String trackingId) {
    _searchController.text = trackingId;
    _tabController.animateTo(1); // Switch to search tab
    _searchProduct();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _qrController?.dispose();
    super.dispose();
  }
}

// Data Models
class TrackingResult {
  final String trackingId;
  final String productName;
  final String producer;
  final String currentStatus;
  final String currentLocation;
  final String lastUpdate;
  final String? estimatedArrival;
  final List<TrackingEvent> timeline;

  TrackingResult({
    required this.trackingId,
    required this.productName,
    required this.producer,
    required this.currentStatus,
    required this.currentLocation,
    required this.lastUpdate,
    this.estimatedArrival,
    required this.timeline,
  });
}

class TrackingEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isComplete;

  TrackingEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isComplete,
  });
} Complete Implementation
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class TrackAndTracePage extends StatefulWidget {
  const TrackAndTracePage({Key? key}) : super(key: key);

  @override
  State<TrackAndTracePage> createState() => _TrackAndTracePageState();
}

class _TrackAndTracePageState extends State<TrackAndTracePage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  // State
  bool _isScanning = false;
  bool _isSearching
