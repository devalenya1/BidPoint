import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';
import 'package:active_ecommerce_flutter/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_flutter/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_flutter/helpers/format_helper.dart';
import 'package:active_ecommerce_flutter/repositories/profile_repository.dart';
import 'package:flutter/services.dart';

// Import the data model
import '../data_model/user_info_response.dart';

class InviteHistoryPage extends StatefulWidget {
  const InviteHistoryPage({Key? key}) : super(key: key);

  @override
  State<InviteHistoryPage> createState() => _InviteHistoryPageState();
}

class _InviteHistoryPageState extends State<InviteHistoryPage> {
  // ============ LOCAL STATE ============
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  UserInformation? _userInfo;  // Store user info for referral data
  
  // Referral data derived from _userInfo
  int get _totalReferrals => _userInfo?.affiliateLogs?.where((log) => log.bonusType == 'referral').length ?? 0;
  int get _totalPoints => (_userInfo?.balance ?? 0).toInt();
  double get _totalEarnings => _userInfo?.affiliateBalance ?? 0.0;
  String get _referralCode => _userInfo?.referralCode ?? "";
  String get _referralLink => "https://bidpoint.com/ref/$_referralCode";
  
  // Invite history from API
  List<AffiliateLog> get _inviteHistory => _userInfo?.affiliateLogs?.where((log) => 
    log.bonusType == 'referral' && log.cameFrom != null
  ).toList() ?? [];
  
  @override
  void initState() {
    super.initState();
    if (is_logged_in.$ == true) {
      _fetchReferralData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // ============ FETCH REFERRAL DATA FROM API ============
  Future<void> _fetchReferralData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      var response = await ProfileRepository().getUserInfoResponse();
      
      if (response.success == true && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _userInfo = response.data![0];  // Store locally
        });
      }
    } catch (e) {
      print("Error loading referral data: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // ============ PULL TO REFRESH ============
  Future<void> _onPageRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchReferralData();
  }
  
  void _copyToClipboard() {
    if (_referralCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code not available'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
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
  
  String _getReferralName(AffiliateLog log) {
    // If cameFrom has a name, use it, otherwise use generic
    if (log.cameFrom != null && log.cameFrom!.isNotEmpty) {
      return log.cameFrom!;
    }
    return 'Referred User';
  }
  
  // ============ BUILD UI ============
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
          onPressed: _navigateBack,
        ),
      ),
      body: RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        child: _isLoading
            ? _buildShimmer()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // Stats Cards Row
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    
                    // Referral Link Section
                    _buildReferralSection(),
                    const SizedBox(height: 24),
                    
                    // Invite History Section
                    _buildHistorySection(),
                  ],
                ),
              ),
      ),
    );
  }
  
  // ============ SHIMMER LOADING STATE ============
  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // Stats Cards Row Shimmer
          Row(
            children: [
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 90, radius: 16)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 90, radius: 16)),
              const SizedBox(width: 12),
              Expanded(child: ShimmerHelper().buildBasicShimmer(height: 90, radius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Referral Link Section Shimmer
          ShimmerHelper().buildBasicShimmer(height: 80, radius: 12),
          const SizedBox(height: 24),
          
          // History Header Shimmer
          ShimmerHelper().buildBasicShimmer(height: 20, width: 150),
          const SizedBox(height: 16),
          
          // History Items Shimmer
          Column(
            children: List.generate(5, (index) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShimmerHelper().buildBasicShimmer(height: 50, radius: 8),
              ),
            ),
          ),
        ],
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
          value: FormatHelper.formatPrice(_totalEarnings),
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
    final displayLink = _referralCode.isNotEmpty 
        ? _referralLink 
        : 'Referral code not available';
    
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
                    displayLink,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF1A1A2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_referralCode.isNotEmpty)
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
    final history = _inviteHistory;
    
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
        if (history.isEmpty)
          _buildEmptyState()
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 500),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => Divider(
                height: 0,
                color: const Color(0xFFEEF2F8),
              ),
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryItem(item, index);
              },
            ),
          ),
        
        // Pagination (if needed)
        if (history.length > 5)
          _buildPagination(),
      ],
    );
  }
  
  Widget _buildHistoryItem(AffiliateLog item, int index) {
    final pointsValue = (item.amount ?? 0).abs().toInt();
    final isEarned = (item.amount ?? 0) > 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getReferralName(item),
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
              '${isEarned ? '+' : ''}$pointsValue',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isEarned ? const Color(0xFF0092AC) : const Color(0xFFEF4444),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.createdAt != null ? _formatDate(item.createdAt!) : 'Unknown',
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
    final history = _inviteHistory;
    final totalPages = (history.length / 10).ceil();
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages > 5 ? 5 : totalPages, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: index == 0 ? MyTheme.accent_color : Colors.white,
              border: Border.all(color: const Color(0xFFEEF2F8)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: index == 0 ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          );
        }),
      ),
    );
  }
}