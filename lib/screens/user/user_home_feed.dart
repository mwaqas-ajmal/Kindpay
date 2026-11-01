import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/request_storage_service.dart';
import '../chat_screen.dart';
import '../../theme/app_theme.dart';
import 'user_requests_screen.dart';

class UserHomeFeed extends StatefulWidget {

  final String currentUserId;

  const UserHomeFeed({

    super.key,

    required this.currentUserId,
  });

  @override
  State<UserHomeFeed> createState() =>
      _UserHomeFeedState();
}

class _UserHomeFeedState
    extends State<UserHomeFeed> {

  List posts = [];

  bool loading = true;

  Timer? timer;

  @override
  void initState() {

    super.initState();

    loadPosts();

    timer = Timer.periodic(

      const Duration(seconds: 3),

          (_) => loadPosts(),
    );
  }

  // =====================================================
  // LOAD POSTS
  // =====================================================

  Future<void> loadPosts() async {

    var res =
    await ApiService.getPosts();

    if(res['success'] == true){

      setState(() {

        posts =
        res['posts'] ?? [];

        loading = false;
      });

    }else{

      setState(() {

        posts = [];

        loading = false;
      });
    }
  }

  @override
  void dispose() {

    timer?.cancel();

    super.dispose();
  }

  // =====================================================
  // FIX IMAGE URL
  // =====================================================

  String fixImageUrl(String image){

    if(image.startsWith("http")){
      return image;
    }

    return

    "https://digitalghallamandi.online/kind-pay/uploads/$image";
  }

  // =====================================================
  // POST TYPE BADGE CONFIG
  // =====================================================

  Map<String, dynamic> getPostTypeBadge(String postType) {
    switch (postType) {
      case "blood":
        return {
          "icon": Icons.bloodtype_rounded,
          "label": "Blood Donation",
          "color": const Color(0xFFFF4E6A),
          "btnLabel": "Donate Blood",
          "btnIcon": Icons.bloodtype_rounded,
        };
      case "child":
        return {
          "icon": Icons.child_care_rounded,
          "label": "Child Adoption",
          "color": const Color(0xFF00FF9D),
          "btnLabel": "Apply to Adopt",
          "btnIcon": Icons.child_care_rounded,
        };
      default:
        return {
          "icon": Icons.attach_money_rounded,
          "label": "Money Donation",
          "color": AppTheme.primary,
          "btnLabel": "Donate",
          "btnIcon": Icons.favorite_rounded,
        };
    }
  }

  // =====================================================
  // REAL STRIPE DONATION POPUP
  // =====================================================

  Future<void> donatePopup(var post) async {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Donate Securely",
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "Enter Amount",
                  prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppTheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Secure payment powered by Stripe",
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                String amount = amountController.text.trim();
                if (amount.isEmpty) return;

                Navigator.pop(context);

                try {
                  var response = await http.post(
                    Uri.parse("https://digitalghallamandi.online/kind-pay/create_payment_intent.php"),
                    body: {"amount": amount},
                  );

                  var data = jsonDecode(response.body);

                  if (data['success'] != true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'].toString())),
                    );
                    return;
                  }

                  String clientSecret = data['clientSecret'];

                  await Stripe.instance.initPaymentSheet(
                    paymentSheetParameters: SetupPaymentSheetParameters(
                      merchantDisplayName: "KindPay",
                      paymentIntentClientSecret: clientSecret,
                    ),
                  );

                  await Stripe.instance.presentPaymentSheet();

                  var donationRes = await ApiService.makeDonation(
                    widget.currentUserId,
                    post['ngo_id'].toString(),
                    amount,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.secondary,
                      content: Text(donationRes['message'].toString()),
                    ),
                  );
                } catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment Cancelled or Failed")),
                  );
                }
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // 🩸 BLOOD DONATION FORM BOTTOM SHEET
  // =====================================================

  void showBloodDonationForm(var post) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String selectedBloodGroup = "A+";
    DateTime? selectedDate;
    bool submitting = false;

    final bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 1.0,
                minChildSize: 0.5,
                maxChildSize: 1.0,
                expand: false,
                builder: (_, scrollCtrl) {
                  return Form(
                    key: formKey,
                    child: ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
                      ),
                      children: [

                        // DRAG HANDLE
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // HEADER
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4E6A), Color(0xFFFF8C94)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bloodtype_rounded, color: Colors.white, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Blood Donation Form",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      post['username']?.toString() ?? "NGO",
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // FULL NAME
                        _buildFormLabel("Full Name"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your full name", Icons.person_outline_rounded),
                        ),
                        const SizedBox(height: 20),

                        // BLOOD GROUP
                        _buildFormLabel("Blood Group"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2836),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBloodGroup,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardColor,
                              icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary),
                              style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15),
                              items: bloodGroups.map((g) {
                                return DropdownMenuItem(
                                  value: g,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF4E6A).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          g,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFFF4E6A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setSheetState(() {
                                  selectedBloodGroup = v!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PHONE
                        _buildFormLabel("Phone Number"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your phone number", Icons.phone_outlined),
                        ),
                        const SizedBox(height: 20),

                        // CITY
                        _buildFormLabel("City"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: cityCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your city", Icons.location_city_outlined),
                        ),
                        const SizedBox(height: 20),

                        // AGE
                        _buildFormLabel("Age"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: ageCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your age", Icons.cake_outlined),
                        ),
                        const SizedBox(height: 20),

                        // AVAILABLE DATE
                        _buildFormLabel("Availability Date"),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFFFF4E6A),
                                      surface: AppTheme.cardColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2836),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  selectedDate == null
                                      ? "Select available date"
                                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                  style: GoogleFonts.outfit(
                                    color: selectedDate == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // SUBMIT BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4E6A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    if (selectedDate == null) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text("Please select availability date")),
                                      );
                                      return;
                                    }
                                    setSheetState(() => submitting = true);

                                    final String availableDateStr =
                                        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                                    var res = await ApiService.submitBloodForm(
                                      userId: widget.currentUserId,
                                      ngoId: post['ngo_id'].toString(),
                                      postId: post['id'].toString(),
                                      fullName: nameCtrl.text.trim(),
                                      bloodGroup: selectedBloodGroup,
                                      phone: phoneCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      age: ageCtrl.text.trim(),
                                      availableDate: availableDateStr,
                                    );

                                    // ✅ Always save locally so it appears in NGO & User screens
                                    await RequestStorageService.saveBloodRequest({
                                      'id': res['request_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                      'user_id': widget.currentUserId,
                                      'ngo_id': post['ngo_id'].toString(),
                                      'post_id': post['id'].toString(),
                                      'ngo_name': post['username']?.toString() ?? 'NGO',
                                      'full_name': nameCtrl.text.trim(),
                                      'blood_group': selectedBloodGroup,
                                      'phone': phoneCtrl.text.trim(),
                                      'city': cityCtrl.text.trim(),
                                      'age': ageCtrl.text.trim(),
                                      'available_date': availableDateStr,
                                      'type': 'blood',
                                      'status': 'pending',
                                      'created_at': DateTime.now().toIso8601String(),
                                    });

                                    setSheetState(() => submitting = false);
                                    Navigator.pop(ctx);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFFFF4E6A),
                                        content: const Text(
                                          "✅ Blood donation request submitted! The NGO will contact you.",
                                        ),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  },
                            child: submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.bloodtype_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Submit Blood Donation Request",
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // 👶 CHILD ADOPTION FORM BOTTOM SHEET
  // =====================================================

  void showAdoptionForm(var post) {
    final formKey = GlobalKey<FormState>();
    final parentNameCtrl = TextEditingController();
    final spouseNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final incomeCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String selectedHomeType = "Owned";
    bool submitting = false;

    final homeTypes = ["Owned", "Rented", "Family Home", "Apartment"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              margin: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 1.0,
                minChildSize: 0.5,
                maxChildSize: 1.0,
                expand: false,
                builder: (_, scrollCtrl) {
                  return Form(
                    key: formKey,
                    child: ListView(
                      controller: scrollCtrl,
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
                      ),
                      children: [

                        // DRAG HANDLE
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.textSecondary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // HEADER
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C980), Color(0xFF00FF9D)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Child Adoption Form",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      post['username']?.toString() ?? "NGO",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // INFO NOTE
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF9D).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF00FF9D).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFF00FF9D), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "All information provided will be kept confidential and reviewed by the NGO.",
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // PARENT NAME
                        _buildFormLabel("Parent / Guardian Name"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: parentNameCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Full name", Icons.person_outline_rounded),
                        ),
                        const SizedBox(height: 20),

                        // SPOUSE NAME
                        _buildFormLabel("Spouse Name (if applicable)"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: spouseNameCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: _inputDeco("Spouse full name (optional)", Icons.people_outline_rounded),
                        ),
                        const SizedBox(height: 20),

                        // PHONE
                        _buildFormLabel("Phone Number"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your phone number", Icons.phone_outlined),
                        ),
                        const SizedBox(height: 20),

                        // EMAIL
                        _buildFormLabel("Email Address"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your email", Icons.email_outlined),
                        ),
                        const SizedBox(height: 20),

                        // ADDRESS
                        _buildFormLabel("Home Address"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: addressCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          maxLines: 2,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Complete address", Icons.home_outlined),
                        ),
                        const SizedBox(height: 20),

                        // CITY
                        _buildFormLabel("City"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: cityCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("Your city", Icons.location_city_outlined),
                        ),
                        const SizedBox(height: 20),

                        // MONTHLY INCOME
                        _buildFormLabel("Monthly Income (PKR)"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: incomeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco("e.g. 50000", Icons.account_balance_wallet_outlined),
                        ),
                        const SizedBox(height: 20),

                        // HOME TYPE
                        _buildFormLabel("Home Type"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2836),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedHomeType,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardColor,
                              icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary),
                              style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 15),
                              items: homeTypes.map((h) {
                                return DropdownMenuItem(
                                  value: h,
                                  child: Text(h),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setSheetState(() {
                                  selectedHomeType = v!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // REASON
                        _buildFormLabel("Reason for Adoption"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: reasonCtrl,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          maxLines: 4,
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          decoration: _inputDeco(
                            "Explain why you want to adopt a child...",
                            Icons.edit_note_rounded,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // SUBMIT BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C980),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() => submitting = true);

                                    var res = await ApiService.submitAdoptionForm(
                                      userId: widget.currentUserId,
                                      ngoId: post['ngo_id'].toString(),
                                      postId: post['id'].toString(),
                                      parentName: parentNameCtrl.text.trim(),
                                      spouseName: spouseNameCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim(),
                                      email: emailCtrl.text.trim(),
                                      address: addressCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      monthlyIncome: incomeCtrl.text.trim(),
                                      homeType: selectedHomeType,
                                      reason: reasonCtrl.text.trim(),
                                    );

                                    // ✅ Always save locally so it appears in NGO & User screens
                                    await RequestStorageService.saveAdoptionRequest({
                                      'id': res['request_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                      'user_id': widget.currentUserId,
                                      'ngo_id': post['ngo_id'].toString(),
                                      'post_id': post['id'].toString(),
                                      'ngo_name': post['username']?.toString() ?? 'NGO',
                                      'parent_name': parentNameCtrl.text.trim(),
                                      'spouse_name': spouseNameCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                      'email': emailCtrl.text.trim(),
                                      'address': addressCtrl.text.trim(),
                                      'city': cityCtrl.text.trim(),
                                      'monthly_income': incomeCtrl.text.trim(),
                                      'home_type': selectedHomeType,
                                      'reason': reasonCtrl.text.trim(),
                                      'type': 'adoption',
                                      'status': 'pending',
                                      'created_at': DateTime.now().toIso8601String(),
                                    });

                                    setSheetState(() => submitting = false);
                                    Navigator.pop(ctx);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFF00C980),
                                        content: const Text(
                                          "✅ Adoption application submitted! The NGO will review and contact you.",
                                        ),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  },
                            child: submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.child_care_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Submit Adoption Application",
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.textSecondary),
    );
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("KindPay Feed"),
        actions: [
          IconButton(
            tooltip: "My Requests & Status",
            icon: Stack(
              children: [
                const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppTheme.primary,
                  size: 26,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4E6A),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserRequestsScreen(
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : posts.isEmpty
              ? Center(
                  child: Text(
                    "No posts found",
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadPosts,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.cardColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      var post = posts[index];
                      String imageUrl = fixImageUrl(post['image'].toString());
                      bool isUrgent = post['urgent'].toString() == "yes";
                      String postType = post['post_type']?.toString() ?? "money";
                      Map<String, dynamic> typeBadge = getPostTypeBadge(postType);
                      Color badgeColor = typeBadge['color'] as Color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [badgeColor, badgeColor.withOpacity(0.6)],
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppTheme.cardColor,
                                      child: Icon(
                                        typeBadge['icon'] as IconData,
                                        color: badgeColor,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['username']?.toString() ?? "",
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.textPrimary,
                                            fontSize: width * 0.045,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUrgent ? "🚨 Urgent Need" : "Normal Donation",
                                          style: GoogleFonts.outfit(
                                            color: isUrgent ? AppTheme.danger : AppTheme.textSecondary,
                                            fontSize: width * 0.035,
                                            fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // POST TYPE BADGE
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(typeBadge['icon'] as IconData, color: badgeColor, size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          typeBadge['label'] as String,
                                          style: GoogleFonts.outfit(
                                            color: badgeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // IMAGE
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.zero),
                              child: Stack(
                                children: [
                                  Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: width < 400 ? 220 : 260,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 240,
                                        color: AppTheme.background,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, size: 50, color: AppTheme.textSecondary),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        post['title']?.toString() ?? "",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: width * 0.05,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // DESCRIPTION
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                post['description']?.toString() ?? "",
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textSecondary,
                                  fontSize: width * 0.038,
                                  height: 1.5,
                                ),
                              ),
                            ),

                            // =====================================================
                            // BUTTONS — SMART BASED ON POST TYPE
                            // =====================================================
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: badgeColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (postType == "blood") {
                                              showBloodDonationForm(post);
                                            } else if (postType == "child") {
                                              showAdoptionForm(post);
                                            } else {
                                              donatePopup(post);
                                            }
                                          },
                                          icon: Icon(typeBadge['btnIcon'] as IconData, size: 18),
                                          label: Text(
                                            typeBadge['btnLabel'] as String,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await ApiService.startChat(
                                              widget.currentUserId,
                                              post['ngo_id'].toString(),
                                            );
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  senderId: widget.currentUserId,
                                                  receiverId: post['ngo_id'].toString(),
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: const BorderSide(color: AppTheme.secondary),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.secondary),
                                          label: Text(
                                            "Chat",
                                            style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ALSO DONATE MONEY option for blood/child posts
                                  if (postType == "blood" || postType == "child") ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => donatePopup(post),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.primary, size: 18),
                                        label: Text(
                                          "Also Donate Money",
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}