import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/request_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/glass_card.dart';

class NgoRequestsScreen extends StatefulWidget {
  final String currentUserId; // NGO ID
  const NgoRequestsScreen({super.key, required this.currentUserId});

  @override
  State<NgoRequestsScreen> createState() => _NgoRequestsScreenState();
}

class _NgoRequestsScreenState extends State<NgoRequestsScreen> with SingleTickerProviderStateMixin {
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

    // 1. Load local persistent requests
    var localBlood = await RequestStorageService.getBloodRequests(ngoId: widget.currentUserId);
    var localAdoption = await RequestStorageService.getAdoptionRequests(ngoId: widget.currentUserId);

    // 2. Fetch server requests (if available)
    var res = await ApiService.getNgoRequests(widget.currentUserId);
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

  Future<void> _updateStatus(String requestId, String type, String newStatus) async {
    // 1. Update in local storage
    await RequestStorageService.updateRequestStatus(
      requestId: requestId,
      type: type,
      newStatus: newStatus,
    );

    // 2. Also send to API backend
    ApiService.updateRequestStatus(
      requestId: requestId,
      type: type,
      status: newStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newStatus == "accepted" ? const Color(0xFF00FF9D) : AppTheme.danger,
          content: Text(
            newStatus == "accepted"
                ? "Request ACCEPTED successfully!"
                : "Request REJECTED.",
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      fetchRequests();
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
      label = "PENDING";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
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
          "Form Submissions & Requests",
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
            Tab(text: "Blood Donations", icon: Icon(Icons.bloodtype_rounded)),
            Tab(text: "Child Adoption", icon: Icon(Icons.child_care_rounded)),
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
      return _buildEmptyState("No blood donation requests received yet.");
    }
    return RefreshIndicator(
      onRefresh: fetchRequests,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bloodRequests.length,
        itemBuilder: (ctx, i) {
          var req = bloodRequests[i];
          String requestId = (req['id'] ?? req['request_id'] ?? "").toString();
          String currentStatus = (req['status'] ?? "pending").toString().toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req['full_name'] ?? req['name'] ?? "Unknown Donor",
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4E6A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFF4E6A).withOpacity(0.5)),
                        ),
                        child: Text(
                          req['blood_group'] ?? "-",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFF4E6A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusBadge(req['status']),
                      const SizedBox(width: 8),
                      Text(
                        "Age: ${req['age'] ?? '-'}",
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, req['phone']),
                  _buildInfoRow(Icons.location_city, req['city']),
                  _buildInfoRow(Icons.calendar_today, "Available Date: ${req['available_date']}"),
                  const SizedBox(height: 16),

                  // ACCEPT / REJECT BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStatus == "accepted"
                                ? const Color(0xFF00FF9D).withOpacity(0.5)
                                : const Color(0xFF00C980),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: currentStatus == "accepted"
                              ? null
                              : () => _updateStatus(requestId, "blood", "accepted"),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(
                            currentStatus == "accepted" ? "Accepted" : "Accept",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: BorderSide(
                              color: currentStatus == "rejected"
                                  ? AppTheme.danger.withOpacity(0.5)
                                  : AppTheme.danger,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: currentStatus == "rejected"
                              ? null
                              : () => _updateStatus(requestId, "blood", "rejected"),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(
                            currentStatus == "rejected" ? "Rejected" : "Reject",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
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
      return _buildEmptyState("No child adoption applications received yet.");
    }
    return RefreshIndicator(
      onRefresh: fetchRequests,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: adoptionRequests.length,
        itemBuilder: (ctx, i) {
          var req = adoptionRequests[i];
          String requestId = (req['id'] ?? req['request_id'] ?? "").toString();
          String currentStatus = (req['status'] ?? "pending").toString().toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Parent: ${req['parent_name'] ?? req['name'] ?? 'Applicant'}",
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
                  if (req['spouse_name'] != null && req['spouse_name'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Spouse: ${req['spouse_name']}",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, req['phone']),
                  _buildInfoRow(Icons.email, req['email']),
                  _buildInfoRow(Icons.location_city, "${req['city']} - ${req['address']}"),
                  _buildInfoRow(Icons.monetization_on, "Income: PKR ${req['monthly_income']}"),
                  _buildInfoRow(Icons.home, "Home: ${req['home_type']}"),
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
                  const SizedBox(height: 16),

                  // ACCEPT / REJECT BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStatus == "accepted"
                                ? const Color(0xFF00FF9D).withOpacity(0.5)
                                : const Color(0xFF00C980),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: currentStatus == "accepted"
                              ? null
                              : () => _updateStatus(requestId, "adoption", "accepted"),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(
                            currentStatus == "accepted" ? "Accepted" : "Accept",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: BorderSide(
                              color: currentStatus == "rejected"
                                  ? AppTheme.danger.withOpacity(0.5)
                                  : AppTheme.danger,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: currentStatus == "rejected"
                              ? null
                              : () => _updateStatus(requestId, "adoption", "rejected"),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(
                            currentStatus == "rejected" ? "Rejected" : "Reject",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
