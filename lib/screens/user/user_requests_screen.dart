import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/request_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/glass_card.dart';

class UserRequestsScreen extends StatefulWidget {
  final String currentUserId;
  const UserRequestsScreen({super.key, required this.currentUserId});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends State<UserRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  List<dynamic> bloodRequests = [];
  List<dynamic> adoptionRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchRequests() async {
    setState(() => loading = true);

    // 1. Fetch local persistent requests
    var localBlood = await RequestStorageService.getBloodRequests(userId: widget.currentUserId);
    var localAdoption = await RequestStorageService.getAdoptionRequests(userId: widget.currentUserId);

    // 2. Fetch server requests (if available)
    var res = await ApiService.getUserRequests(widget.currentUserId);
    var apiBlood = res['blood_donations'] ?? res['blood_requests'] ?? [];
    var apiAdoption = res['adoption_requests'] ?? res['adoptions'] ?? [];

    // Merge server & local, avoiding duplicate keys
    Map<String, dynamic> bloodMap = {};
    for (var item in apiBlood) {
      if (item is Map) {
        String key = (item['id'] ?? item['request_id'] ?? item['phone'] ?? "").toString();
        if (key.isNotEmpty) bloodMap[key] = item;
      }
    }
    for (var item in localBlood) {
      String key = (item['id'] ?? item['request_id'] ?? item['phone'] ?? "").toString();
      if (key.isNotEmpty) bloodMap[key] = item;
    }

    Map<String, dynamic> adoptionMap = {};
    for (var item in apiAdoption) {
      if (item is Map) {
        String key = (item['id'] ?? item['request_id'] ?? item['phone'] ?? "").toString();
        if (key.isNotEmpty) adoptionMap[key] = item;
      }
    }
    for (var item in localAdoption) {
      String key = (item['id'] ?? item['request_id'] ?? item['phone'] ?? "").toString();
      if (key.isNotEmpty) adoptionMap[key] = item;
    }

    if (mounted) {
      setState(() {
        bloodRequests = bloodMap.values.toList();
        adoptionRequests = adoptionMap.values.toList();
        loading = false;
      });
    }
  }

  Widget _buildStatusBadge(String? status) {
    String st = (status ?? "pending").toLowerCase();
    Color badgeColor;
    IconData icon;
    String label;

    if (st == "accepted" || st == "approved") {
      badgeColor = const Color(0xFF00FF9D);
      icon = Icons.check_circle_rounded;
      label = "ACCEPTED";
    } else if (st == "rejected") {
      badgeColor = AppTheme.danger;
      icon = Icons.cancel_rounded;
      label = "REJECTED";
    } else {
      badgeColor = Colors.amber;
      icon = Icons.hourglass_top_rounded;
      label = "PENDING REVIEW";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Requests & Applications",
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: "Blood Requests", icon: Icon(Icons.bloodtype_rounded)),
            Tab(text: "Adoptions", icon: Icon(Icons.child_care_rounded)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            onPressed: fetchRequests,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBloodTab(),
                _buildAdoptionTab(),
              ],
            ),
    );
  }

  Widget _buildBloodTab() {
    if (bloodRequests.isEmpty) {
      return _buildEmptyState("You haven't submitted any blood donation requests yet.");
    }
    return RefreshIndicator(
      onRefresh: fetchRequests,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bloodRequests.length,
        itemBuilder: (ctx, i) {
          var req = bloodRequests[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req['ngo_name'] ?? req['title'] ?? "Blood Donation Request",
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(req['status']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4E6A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF4E6A).withOpacity(0.5)),
                        ),
                        child: Text(
                          "Group: ${req['blood_group'] ?? '-'}",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF4E6A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Age: ${req['age'] ?? '-'}",
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.person, "Donor: ${req['full_name'] ?? req['name']}"),
                  _buildInfoRow(Icons.phone, req['phone']),
                  _buildInfoRow(Icons.location_city, req['city']),
                  _buildInfoRow(Icons.calendar_today, "Available Date: ${req['available_date']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdoptionTab() {
    if (adoptionRequests.isEmpty) {
      return _buildEmptyState("You haven't submitted any adoption applications yet.");
    }
    return RefreshIndicator(
      onRefresh: fetchRequests,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: adoptionRequests.length,
        itemBuilder: (ctx, i) {
          var req = adoptionRequests[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req['ngo_name'] ?? req['title'] ?? "Adoption Application",
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(req['status']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person, "Applicant: ${req['parent_name'] ?? req['name']}"),
                  if (req['spouse_name'] != null && req['spouse_name'].toString().isNotEmpty)
                    _buildInfoRow(Icons.people, "Spouse: ${req['spouse_name']}"),
                  _buildInfoRow(Icons.phone, req['phone']),
                  _buildInfoRow(Icons.email, req['email']),
                  _buildInfoRow(Icons.location_city, "${req['city']} - ${req['address']}"),
                  _buildInfoRow(Icons.monetization_on, "Monthly Income: PKR ${req['monthly_income']}"),
                  _buildInfoRow(Icons.home, "Home Type: ${req['home_type']}"),
                  const SizedBox(height: 10),
                  Text(
                    "Reason for Adoption:",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    req['reason'] ?? "-",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
