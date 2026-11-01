class AppConstants {

  static const String baseUrl =
      "https://digitalghallamandi.online/kind-pay/";

  static const String signupApi =
      "${baseUrl}signup.php";

  static const String loginApi =
      "${baseUrl}login.php";

  static const String createPostApi =
      "${baseUrl}create_post.php";

  static const String getPostsApi =
      "${baseUrl}get_posts.php";

  static const String getUserApi =
    "${baseUrl}get_user.php";

  static const String profileApi =
    "$baseUrl/profile.php";

  // =====================================================
  // 🩸 BLOOD DONATION FORM
  // =====================================================
  static const String submitBloodFormApi =
      "${baseUrl}submit_blood_form.php";

  // =====================================================
  // 👶 CHILD ADOPTION FORM
  // =====================================================
  static const String submitAdoptionFormApi =
      "${baseUrl}submit_adoption_form.php";

  // =====================================================
  // 📋 NGO & USER REQUESTS
  // =====================================================
  static const String getNgoRequestsApi =
      "${baseUrl}get_ngo_requests.php";

  static const String getUserRequestsApi =
      "${baseUrl}get_user_requests.php";

  static const String updateRequestStatusApi =
      "${baseUrl}update_request_status.php";
}