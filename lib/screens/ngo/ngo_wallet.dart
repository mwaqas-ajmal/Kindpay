import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class NgoWallet extends StatefulWidget {

  final String ngoId;

  const NgoWallet({

    super.key,

    required this.ngoId,
  });

  @override
  State<NgoWallet> createState() =>
      _NgoWalletState();
}

class _NgoWalletState
    extends State<NgoWallet> {

  Map wallet = {};

  List donations = [];

  List withdrawHistory = [];

  bool hideBalance = false;

  bool loading = true;

  @override
  void initState() {

    super.initState();

    loadData();
  }

  // =====================================================
  // LOAD DATA
  // =====================================================

  Future<void> loadData() async {

    var w =
    await ApiService.getWallet(
      widget.ngoId,
    );

    var d =
    await ApiService.getDonations(

      widget.ngoId,

      "ngo",
    );

    var withdraws =

    await ApiService
        .getWithdrawHistory(
      widget.ngoId,
    );

    setState(() {

      wallet = w['wallet'] ?? {};

      donations = d;

      withdrawHistory =
      withdraws['history'] ?? [];

      loading = false;
    });
  }

  // =====================================================
  // WITHDRAW POPUP
  // =====================================================

  void withdrawPopup() {
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
            "Withdraw Balance",
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
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Enter Amount",
                  hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.money_rounded, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Secure Stripe withdrawal confirmation",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
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
              child: Text(
                "Cancel",
                style: GoogleFonts.outfit(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                String amount = amountController.text.trim();
                if (amount.isEmpty) return;
                Navigator.pop(context);

                try {
                  // =========================================
                  // PAYMENT INTENT
                  // =========================================
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

                  // =========================================
                  // STRIPE POPUP
                  // =========================================
                  await Stripe.instance.initPaymentSheet(
                    paymentSheetParameters: SetupPaymentSheetParameters(
                      merchantDisplayName: "KindPay Withdraw",
                      paymentIntentClientSecret: clientSecret,
                    ),
                  );

                  await Stripe.instance.presentPaymentSheet();

                  // =========================================
                  // SAVE REQUEST
                  // =========================================
                  var res = await ApiService.requestWithdraw(widget.ngoId, amount);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: res['success'] == true ? AppTheme.primary : AppTheme.danger,
                      content: Text(res['message'].toString()),
                    ),
                  );

                  if (res['success'] == true) {
                    loadData();
                  }
                } catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Withdraw Cancelled")),
                  );
                }
              },
              child: Text(
                "Continue",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("NGO Wallet"),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // =====================================================
                    // WALLET CARD
                    // =====================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "NGO Balance",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    hideBalance = !hideBalance;
                                  });
                                },
                                icon: Icon(
                                  hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Available Balance",
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hideBalance ? "******" : "PKR ${wallet['balance'] ?? 0}",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: withdrawPopup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.account_balance_wallet_rounded),
                              label: Text(
                                "Withdraw",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // =====================================================
                    // DONATION HISTORY
                    // =====================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Donation History",
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.favorite_rounded, color: AppTheme.danger),
                      ],
                    ),
                    const SizedBox(height: 16),

                    donations.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              "No donations yet",
                              style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: donations.length,
                            itemBuilder: (context, index) {
                              var d = donations[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: AppTheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                  title: Text(
                                    d['username']?.toString() ?? "User",
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Text(
                                    d['created_at']?.toString() ?? "",
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    "+ PKR ${d['amount']}",
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 40),

                    // =====================================================
                    // WITHDRAW HISTORY
                    // =====================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Withdraw History",
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.history_rounded, color: AppTheme.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 16),

                    withdrawHistory.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              "No withdraw history",
                              style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: withdrawHistory.length,
                            itemBuilder: (context, index) {
                              var w = withdrawHistory[index];
                              Color statusColor = Colors.orange;

                              if (w['status'] == "approved") {
                                statusColor = AppTheme.primary;
                              } else if (w['status'] == "rejected") {
                                statusColor = AppTheme.danger;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_rounded,
                                      color: statusColor,
                                    ),
                                  ),
                                  title: Text(
                                    "- PKR ${w['amount']}",
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        w['created_at'].toString(),
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          w['status'].toString().toUpperCase(),
                                          style: GoogleFonts.outfit(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: statusColor,
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}