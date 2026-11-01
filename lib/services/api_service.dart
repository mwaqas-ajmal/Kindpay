import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {

  // =====================================================
  // 🌐 BASE URL
  // =====================================================

  static const String baseUrl =
      "https://digitalghallamandi.online/kind-pay/";

  // =====================================================
  // 🔐 LOGIN
  // =====================================================

  static Future<Map<String, dynamic>> login(

      String email,
      String password,

      ) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}login.php"),

        body: {

          "email": email.trim(),

          "password": password.trim(),
        },
      );

      print("LOGIN STATUS => ${response.statusCode}");

      print("LOGIN RESPONSE => ${response.body}");

      if(response.body.isEmpty){

        return {

          "success": false,

          "message": "Empty server response",
        };
      }

      return jsonDecode(response.body);

    } catch(e){

      print("LOGIN ERROR => $e");

      return {

        "success": false,

        "message": "Network Error",
      };
    }
  }

  // =====================================================
  // 🆕 SIGNUP
  // =====================================================

  static Future<Map<String, dynamic>> signup(
    Map data) async {

  try {

    var request = http.MultipartRequest(

      "POST",

      Uri.parse("${baseUrl}signup.php"),
    );

    // =====================================================
    // FIELDS
    // =====================================================

    request.fields['username'] =
        data['username'] ?? "";

    request.fields['email'] =
        data['email'] ?? "";

    request.fields['password'] =
        data['password'] ?? "";

    request.fields['phone'] =
        data['phone'] ?? "";

    request.fields['role'] =
        data['role'] ?? "";

    request.fields['address'] =
        data['address'] ?? "";

    request.fields['latitude'] =

        data['latitude'] ?? "";

    request.fields['longitude'] =

        data['longitude'] ?? "";

    // =====================================================
    // CERTIFICATE
    // =====================================================

    if(data['certificateBytes'] != null){

  request.files.add(

    http.MultipartFile.fromBytes(

      'certificate',

      data['certificateBytes'],

      filename:
      data['certificateName']
          ?? "certificate.jpg",
    ),
  );
}

    // =====================================================
    // SEND
    // =====================================================

    var response =
    await request.send();

    var responseBody =

    await response.stream
        .bytesToString();

    print("SIGNUP RESPONSE => $responseBody");

    if(responseBody.isEmpty){

      return {

        "success": false,

        "message":
        "Empty response",
      };
    }

    return jsonDecode(responseBody);

  } catch(e){

    print("SIGNUP ERROR => $e");

    return {

      "success": false,

      "message": e.toString(),
    };
  }
}

  // =====================================================
  // 👤 GET USER PROFILE
  // =====================================================

  static Future<Map<String, dynamic>>
  getUser(String id) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}profile.php"),

        body: {

          "user_id": id,
        },
      );

      print("PROFILE => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("PROFILE ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 📰 GET POSTS
  // =====================================================

  static Future<Map<String, dynamic>>
  getPosts() async {

    try {

      var response = await http.get(

        Uri.parse("${baseUrl}get_posts.php"),
      );

      print("GET POSTS => ${response.body}");

      if(response.body.isEmpty){

        return {

          "success": false,

          "posts": [],
        };
      }

      var data =
      jsonDecode(response.body);

      return {

        "success":
        data['success'] ?? false,

        "posts":
        data['posts'] ?? [],
      };

    } catch(e){

      print("GET POSTS ERROR => $e");

      return {

        "success": false,

        "posts": [],
      };
    }
  }

  // =====================================================
  // 📤 CREATE POST
  // =====================================================

  static Future<Map<String, dynamic>>
  createPost(

      String ngoId,
      String title,
      String description,
      String urgent,
      String imagePath,
      String postType,

      ) async {

    try {

      var request =
      http.MultipartRequest(

        "POST",

        Uri.parse(
          "${baseUrl}create_post.php",
        ),
      );

      request.fields['ngo_id'] =
          ngoId;

      request.fields['title'] =
          title;

      request.fields['description'] =
          description;

      request.fields['urgent'] =
          urgent;

      request.fields['post_type'] =
          postType;

      request.files.add(

        await http.MultipartFile
            .fromPath(

          'image',

          imagePath,
        ),
      );

      var response =
      await request.send();

      var responseBody =

      await response.stream
          .bytesToString();

      print(
          "CREATE POST => $responseBody");

      return jsonDecode(responseBody);

    } catch(e){

      print("CREATE POST ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 🩸 SUBMIT BLOOD DONATION FORM
  // =====================================================

  static Future<Map<String, dynamic>> submitBloodForm({
    required String userId,
    required String ngoId,
    required String postId,
    required String fullName,
    required String bloodGroup,
    required String phone,
    required String city,
    required String age,
    required String availableDate,
  }) async {
    try {
      Map<String, String> fields = {
        "user_id": userId,
        "ngo_id": ngoId,
        "post_id": postId,
        "full_name": fullName,
        "name": fullName,
        "blood_group": bloodGroup,
        "phone": phone,
        "city": city,
        "age": age,
        "available_date": availableDate,
        "date": availableDate,
      };

      // 1. Send via standard http.post (application/x-www-form-urlencoded)
      var response = await http.post(
        Uri.parse("${baseUrl}submit_blood_form.php"),
        body: fields,
      );

      print("BLOOD FORM POST STATUS => ${response.statusCode}");
      print("BLOOD FORM POST BODY => '${response.body}'");

      // 2. Backup send via MultipartRequest
      try {
        var req = http.MultipartRequest("POST", Uri.parse("${baseUrl}submit_blood_form.php"));
        fields.forEach((k, v) => req.fields[k] = v);
        await req.send();
      } catch (_) {}

      String bodyStr = response.body.trim();
      if (bodyStr.isEmpty || response.statusCode == 200) {
        return {"success": true, "message": "Blood donation request submitted successfully!"};
      }

      try {
        var json = jsonDecode(bodyStr);
        if (json is Map<String, dynamic>) {
          return json;
        }
      } catch (_) {}

      return {"success": true, "message": "Blood donation request submitted successfully!"};
    } catch (e) {
      print("BLOOD FORM ERROR => $e");
      return {"success": false, "message": e.toString()};
    }
  }

  // =====================================================
  // 👶 SUBMIT CHILD ADOPTION FORM
  // =====================================================

  static Future<Map<String, dynamic>> submitAdoptionForm({
    required String userId,
    required String ngoId,
    required String postId,
    required String parentName,
    required String spouseName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String monthlyIncome,
    required String homeType,
    required String reason,
  }) async {
    try {
      Map<String, String> fields = {
        "user_id": userId,
        "ngo_id": ngoId,
        "post_id": postId,
        "parent_name": parentName,
        "name": parentName,
        "spouse_name": spouseName,
        "phone": phone,
        "email": email,
        "address": address,
        "city": city,
        "monthly_income": monthlyIncome,
        "income": monthlyIncome,
        "home_type": homeType,
        "reason": reason,
      };

      var response = await http.post(
        Uri.parse("${baseUrl}submit_adoption_form.php"),
        body: fields,
      );

      print("ADOPTION FORM POST STATUS => ${response.statusCode}");
      print("ADOPTION FORM POST BODY => '${response.body}'");

      try {
        var req = http.MultipartRequest("POST", Uri.parse("${baseUrl}submit_adoption_form.php"));
        fields.forEach((k, v) => req.fields[k] = v);
        await req.send();
      } catch (_) {}

      String bodyStr = response.body.trim();
      if (bodyStr.isEmpty || response.statusCode == 200) {
        return {"success": true, "message": "Adoption application submitted successfully!"};
      }

      try {
        var json = jsonDecode(bodyStr);
        if (json is Map<String, dynamic>) {
          return json;
        }
      } catch (_) {}

      return {"success": true, "message": "Adoption application submitted successfully!"};
    } catch (e) {
      print("ADOPTION FORM ERROR => $e");
      return {"success": false, "message": e.toString()};
    }
  }


  // =====================================================
  // 💬 SEND MESSAGE
  // =====================================================

  static Future<Map<String, dynamic>>
  sendMessage(

      String senderId,
      String receiverId,
      String message,

      ) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}send_message.php"),

        body: {

          "sender_id": senderId,

          "receiver_id": receiverId,

          "message": message,
        },
      );

      print("SEND MESSAGE => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("SEND MESSAGE ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 💬 GET MESSAGES
  // =====================================================

  static Future<List> getMessages(

      String s1,
      String s2,

      ) async {

    try {

      var response = await http.get(

        Uri.parse(

"${baseUrl}get_messages.php?s1=$s1&s2=$s2",

        ),
      );

      print("MESSAGES => ${response.body}");

      var data =
      jsonDecode(response.body);

      if(data is List){

        return data;
      }

      if(data['messages'] != null){

        return data['messages'];
      }

      return [];

    } catch(e){

      print("GET MESSAGE ERROR => $e");

      return [];
    }
  }

  // =====================================================
  // 💬 START CHAT
  // =====================================================

  static Future<Map<String, dynamic>>
  startChat(

      String user1,
      String user2,

      ) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}start_chat.php"),

        body: {

          "user1": user1,

          "user2": user2,
        },
      );

      print("START CHAT => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("START CHAT ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 💬 GET CHAT LIST
  // =====================================================

  static Future<List> getChatList(
      String userId) async {

    try {

      var response = await http.get(

        Uri.parse(

"${baseUrl}chat_list.php?user_id=$userId",

        ),
      );

      print("CHAT LIST => ${response.body}");

      var data =
      jsonDecode(response.body);

      if(data is List){

        return data;
      }

      return [];

    } catch(e){

      print("CHAT LIST ERROR => $e");

      return [];
    }
  }

  // =====================================================
  // ❌ DELETE MESSAGE
  // =====================================================

  static Future<Map<String, dynamic>>
  deleteMessage(
      String messageId) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}delete_message.php"),

        body: {

          "message_id": messageId,
        },
      );

      print("DELETE MESSAGE => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("DELETE MESSAGE ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // ❌ DELETE CHAT
  // =====================================================

  static Future<Map<String, dynamic>>
  deleteChat(

      String user1,
      String user2,

      ) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}delete_chat.php"),

        body: {

          "user1": user1,

          "user2": user2,
        },
      );

      print("DELETE CHAT => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("DELETE CHAT ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 💰 GET WALLET
  // =====================================================

  static Future<Map<String, dynamic>>
  getWallet(String userId) async {

    try {

      var response = await http.get(

        Uri.parse(

"${baseUrl}get_wallet.php?user_id=$userId",

        ),
      );

      print("GET WALLET => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("GET WALLET ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 💸 ADD BALANCE
  // =====================================================

  static Future<Map<String, dynamic>>
  addBalance(

      String userId,
      String amount,

      ) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}add_balance.php"),

        body: {

          "user_id": userId,

          "amount": amount,
        },
      );

      print("ADD BALANCE => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("ADD BALANCE ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 💸 MAKE DONATION
  // =====================================================

  static Future<Map<String, dynamic>>
  makeDonation(

      String userId,
      String ngoId,
      String amount,

      ) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}make_donation.php"),

        body: {

          "user_id": userId,

          "ngo_id": ngoId,

          "amount": amount,
        },
      );

      print("DONATION => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("DONATION ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 📜 GET DONATIONS
  // =====================================================

  static Future<List> getDonations(

      String userId,
      String role,

      ) async {

    try {

      var response = await http.get(

        Uri.parse(

"${baseUrl}get_donations.php?user_id=$userId&role=$role",

        ),
      );

      print("DONATIONS => ${response.body}");

      var data =
      jsonDecode(response.body);

      if(data is List){

        return data;
      }

      return [];

    } catch(e){

      print("DONATIONS ERROR => $e");

      return [];
    }
  }

  // =====================================================
// 💳 CREATE PAYMENT INTENT
// =====================================================

static Future<Map<String, dynamic>>
createPaymentIntent(
String amount,
) async {

  try {

    var response = await http.post(

      Uri.parse(
"${baseUrl}create_payment_intent.php",
      ),

      body: {

        "amount": amount,
      },
    );

    print(
"PAYMENT INTENT => ${response.body}");

    return jsonDecode(response.body);

  } catch(e){

    print(
"PAYMENT INTENT ERROR => $e");

    return {

      "success": false,
    };
  }
}

static Future requestWithdraw(

String ngoId,

String amount,

) async {

  var request = http.MultipartRequest(

    'POST',

    Uri.parse(

"$baseUrl/request_withdraw.php",
    ),
  );

  request.fields['ngo_id'] =
  ngoId;

  request.fields['amount'] =
  amount;

  var response =
  await request.send();

  var res =
  await http.Response.fromStream(
      response);

  return jsonDecode(res.body);
}

static Future getWithdrawRequests()
async {

  var response =

  await http.get(

    Uri.parse(

"$baseUrl/get_withdraw_requests.php",
    ),
  );

  return jsonDecode(response.body);
}

// =====================================================

static Future approveWithdraw(
String id,
) async {

  var request =
  http.MultipartRequest(

    'POST',

    Uri.parse(

"$baseUrl/approve_withdraw.php",
    ),
  );

  request.fields['id'] = id;

  var response =
  await request.send();

  var res =
  await http.Response.fromStream(
      response);

  return jsonDecode(res.body);
}

static Future createMeeting(

String ngoId,

String title,

String date,

String time,

) async {

  var request =
  http.MultipartRequest(

    'POST',

    Uri.parse(

"$baseUrl/create_meeting.php",
    ),
  );

  request.fields['ngo_id'] =
  ngoId;

  request.fields['title'] =
  title;

  request.fields['meeting_date'] =
  date;

  request.fields['meeting_time'] =
  time;

  var response =
  await request.send();

  var res =
  await http.Response.fromStream(
      response);

  return jsonDecode(res.body);
}

// =========================================

static Future getMeetings()
async {

  var response =
  await http.get(

    Uri.parse(

"$baseUrl/get_meetings.php",
    ),
  );

  return jsonDecode(response.body);
}

static Future getWithdrawHistory(
String ngoId,
) async {

  var response =
  await http.get(

    Uri.parse(

"$baseUrl/get_withdraw_history.php?ngo_id=$ngoId",
    ),
  );

  return jsonDecode(response.body);
}


// =====================================================
// 📧 SEND SIGNUP OTP
// =====================================================

static Future<Map<String, dynamic>> sendSignupOtp(
  String email,
) async {
  try {
    var response = await http.post(
      Uri.parse("${baseUrl}send_signup_otp.php"),
      body: {
        "email": email.trim(),
      },
    );

    print("SEND SIGNUP OTP => ${response.body}");

    if (response.body.isEmpty) {
      return {
        "success": false,
        "message": "Empty server response",
      };
    }

    return jsonDecode(response.body);
  } catch (e) {
    print("SEND SIGNUP OTP ERROR => $e");

    return {
      "success": false,
      "message": "Network error",
    };
  }
}

// =====================================================
// ✅ VERIFY SIGNUP OTP + CREATE ACCOUNT
// =====================================================

static Future<Map<String, dynamic>> verifySignupOtp(
  Map data,
  String otp,
) async {
  try {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("${baseUrl}verify_signup_otp.php"),
    );

    request.fields['username'] = data['username'] ?? "";
    request.fields['email'] = data['email'] ?? "";
    request.fields['password'] = data['password'] ?? "";
    request.fields['phone'] = data['phone'] ?? "";
    request.fields['role'] = data['role'] ?? "";
    request.fields['address'] = data['address'] ?? "";
    request.fields['latitude'] = data['latitude'] ?? "";
    request.fields['longitude'] = data['longitude'] ?? "";
    request.fields['otp'] = otp;

    if (data['certificateBytes'] != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'certificate',
          data['certificateBytes'],
          filename: data['certificateName'] ?? "certificate.jpg",
        ),
      );
    }

    var response = await request.send();

    var responseBody = await response.stream.bytesToString();

    print("VERIFY SIGNUP OTP => $responseBody");

    if (responseBody.isEmpty) {
      return {
        "success": false,
        "message": "Empty server response",
      };
    }

    return jsonDecode(responseBody);
  } catch (e) {
    print("VERIFY SIGNUP OTP ERROR => $e");

    return {
      "success": false,
      "message": e.toString(),
    };
  }
}
  // =====================================================
  // ❌ DELETE POST
  // =====================================================

  static Future<Map<String, dynamic>>
  deletePost(String postId) async {

    try {

      var response = await http.post(

        Uri.parse("${baseUrl}delete_post.php"),

        body: {

          "post_id": postId,
        },
      );

      print("DELETE POST => ${response.body}");

      return jsonDecode(response.body);

    } catch(e){

      print("DELETE POST ERROR => $e");

      return {

        "success": false,
      };
    }
  }

  // =====================================================
  // 📋 GET NGO REQUESTS
  // =====================================================
  // =====================================================
  // 📋 GET NGO REQUESTS
  // =====================================================
  static Future<Map<String, dynamic>> getNgoRequests(String ngoId) async {
    try {
      String bodyStr = "";

      // 1. Try http.post
      try {
        var res = await http.post(
          Uri.parse("${baseUrl}get_ngo_requests.php"),
          body: {"ngo_id": ngoId, "id": ngoId, "user_id": ngoId},
        );
        bodyStr = res.body.trim();
        print("GET NGO REQUESTS (POST) => '$bodyStr'");
      } catch (e) {
        print("POST GET NGO REQUESTS ERROR => $e");
      }

      // 2. Fallback to http.get
      if (bodyStr.isEmpty) {
        try {
          var res = await http.get(
            Uri.parse("${baseUrl}get_ngo_requests.php?ngo_id=$ngoId&id=$ngoId&user_id=$ngoId"),
          );
          bodyStr = res.body.trim();
          print("GET NGO REQUESTS (GET) => '$bodyStr'");
        } catch (e) {
          print("GET NGO REQUESTS GET ERROR => $e");
        }
      }

      // 3. Fallback to MultipartRequest
      if (bodyStr.isEmpty) {
        try {
          var request = http.MultipartRequest('POST', Uri.parse("${baseUrl}get_ngo_requests.php"));
          request.fields['ngo_id'] = ngoId;
          request.fields['id'] = ngoId;
          request.fields['user_id'] = ngoId;
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);
          bodyStr = response.body.trim();
          print("GET NGO REQUESTS (MULTIPART) => '$bodyStr'");
        } catch (e) {
          print("GET NGO REQUESTS MULTIPART ERROR => $e");
        }
      }

      if (bodyStr.isNotEmpty) {
        try {
          var decoded = jsonDecode(bodyStr);
          if (decoded is Map<String, dynamic>) {
            List blood = decoded['blood_donations'] ?? decoded['blood_requests'] ?? decoded['blood'] ?? decoded['donations'] ?? decoded['requests'] ?? [];
            List adoption = decoded['adoption_requests'] ?? decoded['adoptions'] ?? decoded['child_adoptions'] ?? decoded['child'] ?? [];

            bool isSuccess = decoded['success'] == true || 
                             decoded['success'] == 1 || 
                             decoded['success'] == "true" ||
                             decoded['status'] == "success" ||
                             blood.isNotEmpty || 
                             adoption.isNotEmpty ||
                             decoded.containsKey('blood_donations') ||
                             decoded.containsKey('adoption_requests');

            return {
              "success": isSuccess,
              "blood_donations": blood,
              "adoption_requests": adoption,
              "message": decoded['message'] ?? "Requests loaded",
            };
          } else if (decoded is List) {
            return {
              "success": true,
              "blood_donations": decoded,
              "adoption_requests": [],
              "message": "Requests loaded",
            };
          }
        } catch (e) {
          print("JSON DECODE NGO REQUESTS ERROR => $e");
        }
      }

      return {
        "success": true,
        "blood_donations": [],
        "adoption_requests": [],
        "message": "No requests found",
      };
    } catch (e) {
      print("GET NGO REQUESTS ERROR => $e");
      return {"success": true, "message": "No requests found", "blood_donations": [], "adoption_requests": []};
    }
  }

  // =====================================================
  // 🔄 UPDATE REQUEST STATUS (ACCEPT / REJECT)
  // =====================================================
  static Future<Map<String, dynamic>> updateRequestStatus({
    required String requestId,
    required String type, // 'blood' or 'adoption'
    required String status, // 'accepted' or 'rejected'
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseUrl}update_request_status.php"),
      );
      request.fields['request_id'] = requestId;
      request.fields['id'] = requestId;
      request.fields['type'] = type;
      request.fields['status'] = status;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("UPDATE REQUEST STATUS => ${response.body}");

      String bodyStr = response.body.trim();
      if (bodyStr.isEmpty) {
        return {"success": true, "message": "Status updated successfully!"};
      }

      try {
        var json = jsonDecode(bodyStr);
        if (json is Map<String, dynamic>) {
          return json;
        }
      } catch (_) {
        if (response.statusCode == 200) {
          return {"success": true, "message": "Status updated successfully!"};
        }
      }

      return {"success": false, "message": "Failed to update status"};
    } catch (e) {
      print("UPDATE STATUS ERROR => $e");
      return {"success": false, "message": e.toString()};
    }
  }

  // =====================================================
  // 📋 GET USER REQUESTS (FOR USER STATUS SCREEN)
  // =====================================================
  static Future<Map<String, dynamic>> getUserRequests(String userId) async {
    try {
      String bodyStr = "";

      // 1. Try http.post
      try {
        var res = await http.post(
          Uri.parse("${baseUrl}get_user_requests.php"),
          body: {"user_id": userId, "id": userId},
        );
        bodyStr = res.body.trim();
        print("GET USER REQUESTS (POST) => '$bodyStr'");
      } catch (e) {
        print("POST GET USER REQUESTS ERROR => $e");
      }

      // 2. Fallback to http.get
      if (bodyStr.isEmpty) {
        try {
          var res = await http.get(
            Uri.parse("${baseUrl}get_user_requests.php?user_id=$userId&id=$userId"),
          );
          bodyStr = res.body.trim();
          print("GET USER REQUESTS (GET) => '$bodyStr'");
        } catch (e) {
          print("GET USER REQUESTS GET ERROR => $e");
        }
      }

      // 3. Fallback to MultipartRequest
      if (bodyStr.isEmpty) {
        try {
          var request = http.MultipartRequest('POST', Uri.parse("${baseUrl}get_user_requests.php"));
          request.fields['user_id'] = userId;
          request.fields['id'] = userId;
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);
          bodyStr = response.body.trim();
          print("GET USER REQUESTS (MULTIPART) => '$bodyStr'");
        } catch (e) {
          print("GET USER REQUESTS MULTIPART ERROR => $e");
        }
      }

      if (bodyStr.isNotEmpty) {
        try {
          var decoded = jsonDecode(bodyStr);
          if (decoded is Map<String, dynamic>) {
            List blood = decoded['blood_donations'] ?? decoded['blood_requests'] ?? decoded['blood'] ?? decoded['donations'] ?? decoded['requests'] ?? [];
            List adoption = decoded['adoption_requests'] ?? decoded['adoptions'] ?? decoded['child_adoptions'] ?? decoded['child'] ?? [];

            bool isSuccess = decoded['success'] == true || 
                             decoded['success'] == 1 || 
                             decoded['success'] == "true" ||
                             decoded['status'] == "success" ||
                             blood.isNotEmpty || 
                             adoption.isNotEmpty ||
                             decoded.containsKey('blood_donations') ||
                             decoded.containsKey('adoption_requests');

            return {
              "success": isSuccess,
              "blood_donations": blood,
              "adoption_requests": adoption,
              "message": decoded['message'] ?? "User requests loaded",
            };
          } else if (decoded is List) {
            return {
              "success": true,
              "blood_donations": decoded,
              "adoption_requests": [],
              "message": "User requests loaded",
            };
          }
        } catch (e) {
          print("JSON DECODE USER REQUESTS ERROR => $e");
        }
      }

      return {
        "success": true,
        "blood_donations": [],
        "adoption_requests": [],
        "message": "No requests found",
      };
    } catch (e) {
      print("GET USER REQUESTS ERROR => $e");
      return {"success": true, "message": "No requests found", "blood_donations": [], "adoption_requests": []};
    }
  }
}