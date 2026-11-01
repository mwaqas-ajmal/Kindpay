import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../utils/gradient_button.dart';

class NgoCreatePost extends StatefulWidget {

  final String ngoId;

  const NgoCreatePost({

    super.key,

    required this.ngoId,
  });

  @override
  State<NgoCreatePost> createState() =>
      _NgoCreatePostState();
}

class _NgoCreatePostState
    extends State<NgoCreatePost> {

  TextEditingController titleController =
  TextEditingController();

  TextEditingController descController =
  TextEditingController();

  PlatformFile? imageFile;

  bool urgent = false;

  bool loading = false;

  // =====================================================
  // POST TYPE SELECTION
  // =====================================================

  String selectedPostType = "money";

  final List<Map<String, dynamic>> postTypes = [
    {
      "value": "money",
      "label": "Money Donation",
      "icon": Icons.attach_money_rounded,
      "color": Color(0xFF00D4FF),
      "description": "Collect financial donations via Stripe",
    },
    {
      "value": "blood",
      "label": "Blood Donation",
      "icon": Icons.bloodtype_rounded,
      "color": Color(0xFFFF4E6A),
      "description": "Accept blood donor registrations",
    },
    {
      "value": "child",
      "label": "Child Adoption",
      "icon": Icons.child_care_rounded,
      "color": Color(0xFF00FF9D),
      "description": "Accept child adoption applications",
    },
  ];

  // =====================================================
  // PICK IMAGE
  // =====================================================

  Future<void> pickImage() async {

    FilePickerResult? result =

    await FilePicker.platform.pickFiles(

      type: FileType.image,

      withData: true,
    );

    if(result != null){

      setState(() {

        imageFile =
        result.files.first;
      });
    }
  }

  // =====================================================
  // CREATE POST
  // =====================================================

  Future<void> createPost() async {

    if(titleController.text.trim().isEmpty){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Enter title",
          ),
        ),
      );

      return;
    }

    if(descController.text.trim().isEmpty){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Enter description",
          ),
        ),
      );

      return;
    }

    if(imageFile == null){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Select image",
          ),
        ),
      );

      return;
    }

    setState(() {

      loading = true;
    });

    try {

      var request =
      http.MultipartRequest(

        'POST',

        Uri.parse(
          AppConstants.createPostApi,
        ),
      );

      // =====================================================
      // FIELDS
      // =====================================================

      request.fields['ngo_id'] =
          widget.ngoId;

      request.fields['title'] =

          titleController.text.trim();

      request.fields['description'] =

          descController.text.trim();

      request.fields['urgent'] =

      urgent

          ? "yes"

          : "no";

      request.fields['post_type'] =
          selectedPostType;

      // =====================================================
      // IMAGE
      // =====================================================

      request.files.add(

        http.MultipartFile.fromBytes(

          'image',

          imageFile!.bytes!,

          filename:
          imageFile!.name,
        ),
      );

      var response =
      await request.send();

      if(response.statusCode == 200){

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Post uploaded successfully",
            ),
          ),
        );

        Navigator.pop(context);

      }else{

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Upload failed",
            ),
          ),
        );
      }

    } catch(e){

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content: Text(
            "Error: $e",
          ),
        ),
      );
    }

    setState(() {

      loading = false;
    });
  }

  // =====================================================
  // MAIN UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Create Post"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // HEADER CARD
            // =====================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Create Donation Post",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Share your NGO needs with donors",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // =====================================================
            // POST TYPE SELECTION
            // =====================================================
            Text(
              "Post Type",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Select what kind of donation this post needs",
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            ...postTypes.map((type) {
              bool isSelected = selectedPostType == type['value'];
              Color typeColor = type['color'] as Color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPostType = type['value'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? typeColor.withOpacity(0.12)
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? typeColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: typeColor.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(isSelected ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          type['icon'] as IconData,
                          color: typeColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type['label'] as String,
                              style: GoogleFonts.outfit(
                                color: isSelected ? typeColor : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type['description'] as String,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? typeColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? typeColor : AppTheme.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // =====================================================
            // TITLE FIELD
            // =====================================================
            Text(
              "Post Title",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Enter post title",
                prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // =====================================================
            // DESCRIPTION FIELD
            // =====================================================
            Text(
              "Description",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 5,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: "Explain donation need...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // =====================================================
            // URGENT SWITCH
            // =====================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SwitchListTile(
                value: urgent,
                activeColor: AppTheme.danger,
                activeTrackColor: AppTheme.danger.withOpacity(0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: AppTheme.background,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) {
                  setState(() {
                    urgent = v;
                  });
                },
                title: Text(
                  "Urgent Need",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  urgent ? "This post will be highlighted" : "Normal donation request",
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // =====================================================
            // IMAGE PICKER
            // =====================================================
            Text(
              "Upload Image",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: imageFile != null ? AppTheme.primary : AppTheme.cardColor,
                    width: 2,
                  ),
                ),
                child: imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, size: 64, color: AppTheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            "Tap to upload image",
                            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.memory(
                          imageFile!.bytes!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // =====================================================
            // UPLOAD BUTTON
            // =====================================================
            GradientButton(
              text: "Upload Post",
              onPressed: loading ? null : createPost,
              isLoading: loading,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}