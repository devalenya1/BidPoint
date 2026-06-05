import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:flutter/services.dart';

class InviteHistoryPage extends StatefulWidget {
  const InviteHistoryPage({Key? key}) : super(key: key);

  @override
  State<InviteHistoryPage> createState() => _InviteHistoryPageState();
}

class _InviteHistoryPageState extends State<InviteHistoryPage> {
  // Demo data
  int _totalReferrals = 12;
  int _totalPoints = 1250;
  double _totalEarnings = 1250.50;
  String _referralCode = "BIDPOINT2024";
  String _referralLink = "";
  
  // Demo invite history data
  List<Map<String, dynamic>> _inviteHistory = [];
  
  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }
  
  void _loadDemoData() {
    _referralLink = "https://bidpoint.com/ref/$_referralCode";
    
    _inviteHistory = [
      {
        'id': 1,
        'name': 'Sarah Johnson',
        'points': 100,
        'date': DateTime(2024, 5, 15),
      },
      {
        'id': 2,
        'name': 'Mike Thompson',
        'points': 100,
        'date': DateTime(2024, 5, 14),
      },
      {
        'id': 3,
        'name': 'Emily Davis',
        'points': 100,
        'date': DateTime(2024, 5, 10),
      },
      {
        'id': 4,
        'name': 'James Wilson',
        'points': 100,
        'date': DateTime(2024, 5, 5),
      },
      {
        'id': 5,
        'name': 'Lisa Anderson',
        'points': 100,
        'date': DateTime(2024, 4, 28),
      },
      {
        'id': 6,
        'name': 'Robert Brown',
        'points': 100,
        'date': DateTime(2024, 4, 20),
      },
      {
        'id': 7,
        'name': 'Maria Garcia',
        'points': 100,
        'date': DateTime(2024, 4, 15),
      },
      {
        'id': 8,
        'name': 'David Lee',
        'points': 100,
        'date': DateTime(2024, 4, 10),
      },
    ];
  }
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _referralLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copied_to_clipboard),
        backgroundColor: MyTheme.accent_color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.invite_history,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            // Stats Cards Row
            _buildStatsRow(),
            const SizedBox(height: 24),
            
            // Invite History Section
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          label: AppLocalizations.of(context)!.referrals_ucf,
          value: '$_totalReferrals',
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: AppLocalizations.of(context)!.points_ucf,
          value: '$_totalPoints',
          unit: 'pts',
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: AppLocalizations.of(context)!.earnings_ucf,
          value: '\$${_totalEarnings.toStringAsFixed(2)}',
        ),
      ],
    );
  }
  
  Widget _buildStatCard({
    required String label,
    required String value,
    String? unit,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF2F8)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
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
  
  Widget _buildReferralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.your_referral_link,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEF2F8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    _referralLink,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF1A1A2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _copyToClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: MyTheme.accent_color,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.copy,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.copy_ucf,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHistorySection() {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFEEF2F8),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  AppLocalizations.of(context)!.referral_name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  AppLocalizations.of(context)!.points_ucf,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  AppLocalizations.of(context)!.date_ucf,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // History List
        if (_inviteHistory.isEmpty)
          _buildEmptyState()
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _inviteHistory.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: const Color(0xFFEEF2F8),
              ),
              itemBuilder: (context, index) {
                final item = _inviteHistory[index];
                return _buildHistoryItem(item);
              },
            ),
          ),
        
        // Pagination (if needed)
        if (_inviteHistory.length > 5)
          _buildPagination(),
      ],
    );
  }
  
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item['points']}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0092AC),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(item['date']),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Text(
            '📋',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.no_referral_history_yet,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.share_referral_link_to_start_earning,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFEEF2F8)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}