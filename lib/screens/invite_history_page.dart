import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:active_ecommerce_flutter/my_theme.dart';

class InviteHistoryPage extends StatelessWidget {
  const InviteHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Demo invite history data
    final List<Map<String, dynamic>> inviteHistory = [
      {
        'id': 1,
        'name': 'Sarah Johnson',
        'email': 'sarah@example.com',
        'date': DateTime(2024, 5, 15),
        'status': 'completed',
        'points': 100,
      },
      {
        'id': 2,
        'name': 'Mike Thompson',
        'email': 'mike@example.com',
        'date': DateTime(2024, 5, 14),
        'status': 'completed',
        'points': 100,
      },
      {
        'id': 3,
        'name': 'Emily Davis',
        'email': 'emily@example.com',
        'date': DateTime(2024, 5, 10),
        'status': 'pending',
        'points': 0,
      },
      {
        'id': 4,
        'name': 'James Wilson',
        'email': 'james@example.com',
        'date': DateTime(2024, 5, 5),
        'status': 'completed',
        'points': 100,
      },
    ];

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
      body: inviteHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 64,
                    color: Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.no_invite_history,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: inviteHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = inviteHistory[index];
                final isCompleted = item['status'] == 'completed';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFFE5F6FF)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle : Icons.pending,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['email'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item['date'].day}/${item['date'].month}/${item['date'].year}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isCompleted)
                            Text(
                              '+${item['points']} ${AppLocalizations.of(context)!.points_ucf}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCompleted
                                  ? AppLocalizations.of(context)!.completed_ucf
                                  : AppLocalizations.of(context)!.pending_ucf,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFEF6C00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}