import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class UserWallet extends StatefulWidget {

  final String userId;

  const UserWallet({

    super.key,

    required this.userId,
  });

  @override
  State<UserWallet> createState() =>
      _UserWalletState();
}

class _UserWalletState
    extends State<UserWallet> {

  Map wallet = {};

  bool loading = true;

  bool hideBalance = false;

  final TextEditingController
  amountController =
  TextEditingController();

  @override
  void initState() {

    super.initState();

    loadWallet();
  }

  // =====================================================
  // LOAD WALLET
  // =====================================================

  Future<void> loadWallet() async {

    var w =
    await ApiService.getWallet(

      widget.userId,
    );

    setState(() {

      wallet =
      w['wallet'] ?? {};

      loading = false;
    });
  }

  // =====================================================
  // STRIPE PAYMENT
  // =====================================================

  Future<void> makePayment(
      String amount) async {

    try {

      // ===============================================
      // CREATE PAYMENT INTENT
      // ===============================================

      var response = await http.post(

        Uri.parse(

"https://digitalghallamandi.online/kind-pay/create_payment_intent.php",

        ),

        body: {

          "amount": amount,
        },
      );

      var data =
      jsonDecode(response.body);

      print(data);

      if(data['success'] != true){

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(

            content:
            Text(data['message']),
          ),
        );

        return;
      }

      String clientSecret =
      data['clientSecret'];

      // ===============================================
      // INIT PAYMENT SHEET
      // ===============================================

      await Stripe.instance
          .initPaymentSheet(

        paymentSheetParameters:

        SetupPaymentSheetParameters(

          paymentIntentClientSecret:

          clientSecret,

          merchantDisplayName:
          "KindPay",
        ),
      );

      // ===============================================
      // PRESENT PAYMENT SHEET
      // ===============================================

      await Stripe.instance
          .presentPaymentSheet();

      // ===============================================
      // ADD BALANCE IN DATABASE
      // ===============================================

      var addBalanceRes =

      await ApiService.addBalance(

        widget.userId,

        amount,
      );

      print(addBalanceRes);

      if(addBalanceRes['success']
      == true){

        await loadWallet();

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(

"Payment Successful 🎉",

            ),
          ),
        );
      }

    } catch(e){

      print(e);

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:
          Text("Payment Failed"),
        ),
      );
    }
  }

  // =====================================================
  // ADD MONEY DIALOG
  // =====================================================

  void showAddMoneyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Add Money",
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
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
              prefixIcon: const Icon(Icons.attach_money_rounded, color: AppTheme.primary),
            ),
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
                Navigator.pop(context);
                String amount = amountController.text.trim();
                if (amount.isEmpty) return;
                await makePayment(amount);
                amountController.clear();
              },
              child: Text(
                "Pay",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Wallet"),
        actions: [
          IconButton(
            onPressed: loadWallet,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ===========================================
                  // WALLET CARD
                  // ===========================================
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
                              "Current Balance",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 16,
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
                        const SizedBox(height: 16),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Secure Stripe Wallet",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ===========================================
                  // ADD MONEY BUTTON
                  // ===========================================
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        shadowColor: AppTheme.primary.withOpacity(0.5),
                      ),
                      onPressed: showAddMoneyDialog,
                      icon: const Icon(
                        Icons.add_card_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: Text(
                        "Add Money",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ===========================================
                  // INFO CARD
                  // ===========================================
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: AppTheme.secondary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Payments are secured by Stripe",
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Your card information is encrypted and never stored inside the app. We prioritize your financial security.",
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            height: 1.5,
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
}