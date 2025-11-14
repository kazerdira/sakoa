# 🔔 Firebase Push Notifications Implementation Guide

## ✅ What You Already Have

Good news! You're 80% ready:

1. ✅ **Firebase Admin SDK JSON**: `sakoa-64c2e-firebase-adminsdk-fbsvc-4abb13ca84.json`
2. ✅ **Laravel Firebase Package**: `kreait/laravel-firebase: ^5.0` installed
3. ✅ **Environment Variable**: `FIREBASE_CREDENTIALS` configured in `.env`
4. ✅ **FCM Token Binding**: Flutter app already sends FCM token to backend
5. ✅ **Notification Handler**: `FirebaseMassagingHandler.dart` exists in Flutter

## 🎯 What We Need to Do

### Step 1: Verify Firebase Package Configuration

**File:** `config/firebase.php`

```php
<?php

return [
    'credentials' => [
        'file' => env('FIREBASE_CREDENTIALS'),
        // Alternative: 'auto' - auto-discover credentials
    ],

    'database' => [
        'url' => env('FIREBASE_DATABASE_URL'),
    ],

    'dynamic_links' => [
        'default_domain' => env('FIREBASE_DYNAMIC_LINKS_DEFAULT_DOMAIN'),
    ],

    'storage' => [
        'default_bucket' => env('FIREBASE_STORAGE_DEFAULT_BUCKET'),
    ],
];
```

### Step 2: Check User Model for FCM Token

**File:** `app/Models/User.php`

Make sure your users table has an `fcmtoken` column:

```php
// Migration (if not exists)
Schema::table('users', function (Blueprint $table) {
    $table->string('fcmtoken')->nullable()->after('remember_token');
});
```

### Step 3: Create Notification Service

**File:** `app/Services/FirebaseNotificationService.php` (NEW)

```php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Illuminate\Support\Facades\Log;

class FirebaseNotificationService
{
    protected $messaging;

    public function __construct()
    {
        $factory = (new Factory)->withServiceAccount(base_path(env('FIREBASE_CREDENTIALS')));
        $this->messaging = $factory->createMessaging();
    }

    /**
     * Send contact request notification
     */
    public function sendContactRequestNotification($recipientToken, $senderName, $senderAvatar, $senderToken)
    {
        if (empty($recipientToken)) {
            Log::warning('Cannot send notification: recipient FCM token is empty');
            return false;
        }

        $notification = Notification::create(
            '📬 New Contact Request',
            "$senderName wants to connect with you"
        );

        $data = [
            'type' => 'contact_request',
            'sender_token' => $senderToken,
            'sender_name' => $senderName,
            'sender_avatar' => $senderAvatar,
            'action' => 'open_contacts_requests_tab',
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        $message = CloudMessage::withTarget('token', $recipientToken)
            ->withNotification($notification)
            ->withData($data);

        try {
            $result = $this->messaging->send($message);
            Log::info("Contact request notification sent successfully", [
                'recipient' => $recipientToken,
                'sender' => $senderName,
                'result' => $result
            ]);
            return true;
        } catch (\Exception $e) {
            Log::error("Failed to send contact request notification: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send contact accepted notification
     */
    public function sendContactAcceptedNotification($recipientToken, $accepterName, $accepterAvatar, $accepterToken)
    {
        if (empty($recipientToken)) {
            Log::warning('Cannot send notification: recipient FCM token is empty');
            return false;
        }

        $notification = Notification::create(
            '✅ Contact Request Accepted',
            "$accepterName accepted your contact request"
        );

        $data = [
            'type' => 'contact_accepted',
            'accepter_token' => $accepterToken,
            'accepter_name' => $accepterName,
            'accepter_avatar' => $accepterAvatar,
            'action' => 'open_chat',
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        $message = CloudMessage::withTarget('token', $recipientToken)
            ->withNotification($notification)
            ->withData($data);

        try {
            $result = $this->messaging->send($message);
            Log::info("Contact accepted notification sent successfully", [
                'recipient' => $recipientToken,
                'accepter' => $accepterName,
                'result' => $result
            ]);
            return true;
        } catch (\Exception $e) {
            Log::error("Failed to send contact accepted notification: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send new message notification
     */
    public function sendNewMessageNotification($recipientToken, $senderName, $senderAvatar, $messageText, $chatDocId)
    {
        if (empty($recipientToken)) {
            return false;
        }

        $notification = Notification::create(
            "💬 $senderName",
            $messageText
        );

        $data = [
            'type' => 'new_message',
            'sender_name' => $senderName,
            'sender_avatar' => $senderAvatar,
            'message' => $messageText,
            'chat_doc_id' => $chatDocId,
            'action' => 'open_chat',
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
        ];

        $message = CloudMessage::withTarget('token', $recipientToken)
            ->withNotification($notification)
            ->withData($data);

        try {
            $this->messaging->send($message);
            return true;
        } catch (\Exception $e) {
            Log::error("Failed to send message notification: " . $e->getMessage());
            return false;
        }
    }
}
```

### Step 4: Create Notification Controller

**File:** `app/Http/Controllers/Api/NotificationController.php` (NEW)

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\FirebaseNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    protected $notificationService;

    public function __construct(FirebaseNotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Send contact request notification
     * POST /api/notifications/contact-request
     */
    public function contactRequest(Request $request)
    {
        $validated = $request->validate([
            'recipient_token' => 'required|string',
            'sender_token' => 'required|string',
            'sender_name' => 'required|string',
            'sender_avatar' => 'nullable|string',
        ]);

        // Get recipient's FCM token from users table
        $recipient = DB::table('users')
            ->where('token', $validated['recipient_token'])
            ->first();

        if (!$recipient || empty($recipient->fcmtoken)) {
            return response()->json([
                'code' => 1,
                'msg' => 'Recipient not found or FCM token not available',
            ], 404);
        }

        $success = $this->notificationService->sendContactRequestNotification(
            $recipient->fcmtoken,
            $validated['sender_name'],
            $validated['sender_avatar'] ?? '',
            $validated['sender_token']
        );

        if ($success) {
            return response()->json([
                'code' => 0,
                'msg' => 'Notification sent successfully',
            ]);
        } else {
            return response()->json([
                'code' => 1,
                'msg' => 'Failed to send notification',
            ], 500);
        }
    }

    /**
     * Send contact accepted notification
     * POST /api/notifications/contact-accepted
     */
    public function contactAccepted(Request $request)
    {
        $validated = $request->validate([
            'recipient_token' => 'required|string',
            'accepter_token' => 'required|string',
            'accepter_name' => 'required|string',
            'accepter_avatar' => 'nullable|string',
        ]);

        // Get recipient's FCM token from users table
        $recipient = DB::table('users')
            ->where('token', $validated['recipient_token'])
            ->first();

        if (!$recipient || empty($recipient->fcmtoken)) {
            return response()->json([
                'code' => 1,
                'msg' => 'Recipient not found or FCM token not available',
            ], 404);
        }

        $success = $this->notificationService->sendContactAcceptedNotification(
            $recipient->fcmtoken,
            $validated['accepter_name'],
            $validated['accepter_avatar'] ?? '',
            $validated['accepter_token']
        );

        if ($success) {
            return response()->json([
                'code' => 0,
                'msg' => 'Notification sent successfully',
            ]);
        } else {
            return response()->json([
                'code' => 1,
                'msg' => 'Failed to send notification',
            ], 500);
        }
    }
}
```

### Step 5: Add API Routes

**File:** `routes/api.php`

Add these routes:

```php
use App\Http\Controllers\Api\NotificationController;

// Notification routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/notifications/contact-request', [NotificationController::class, 'contactRequest']);
    Route::post('/notifications/contact-accepted', [NotificationController::class, 'contactAccepted']);
});
```

### Step 6: Update Flutter - Add Notification Endpoints

**File:** `chatty/lib/common/apis/chat.dart`

Add these methods:

```dart
class ChatAPI {
  // ... existing methods ...

  /// Send contact request notification
  static Future<ResponseEntity> send_contact_request_notification({
    required String recipientToken,
    required String senderToken,
    required String senderName,
    String? senderAvatar,
  }) async {
    var response = await HttpUtil().post(
      'api/notifications/contact-request',
      queryParameters: {
        'recipient_token': recipientToken,
        'sender_token': senderToken,
        'sender_name': senderName,
        'sender_avatar': senderAvatar ?? '',
      },
    );
    return ResponseEntity.fromJson(response);
  }

  /// Send contact accepted notification
  static Future<ResponseEntity> send_contact_accepted_notification({
    required String recipientToken,
    required String accepterToken,
    required String accepterName,
    String? accepterAvatar,
  }) async {
    var response = await HttpUtil().post(
      'api/notifications/contact-accepted',
      queryParameters: {
        'recipient_token': recipientToken,
        'accepter_token': accepterToken,
        'accepter_name': accepterName,
        'accepter_avatar': accepterAvatar ?? '',
      },
    );
    return ResponseEntity.fromJson(response);
  }
}
```

### Step 7: Update ContactController to Send Notifications

**File:** `chatty/lib/pages/contact/controller.dart`

Find the `sendContactRequest` method and add notification:

```dart
Future<void> sendContactRequest(UserItem user) async {
  try {
    // ... existing code to send request ...
    
    // 🔥 NEW: Send push notification
    await ChatAPI.send_contact_request_notification(
      recipientToken: user.token!,
      senderToken: token,
      senderName: UserStore.to.profile.name ?? 'Someone',
      senderAvatar: UserStore.to.profile.avatar,
    );
    
    print('[ContactController] ✅ Contact request notification sent');
  } catch (e) {
    print('[ContactController] ⚠️ Notification failed: $e');
    // Don't fail the request if notification fails
  }
}
```

Find the `acceptContactRequest` method and add notification:

```dart
Future<void> acceptContactRequest(ContactEntity request) async {
  try {
    // ... existing code to accept request ...
    
    // 🔥 NEW: Send push notification to original sender
    await ChatAPI.send_contact_accepted_notification(
      recipientToken: request.user_token!, // Original sender
      accepterToken: token,
      accepterName: UserStore.to.profile.name ?? 'Someone',
      accepterAvatar: UserStore.to.profile.avatar,
    );
    
    print('[ContactController] ✅ Contact accepted notification sent');
  } catch (e) {
    print('[ContactController] ⚠️ Notification failed: $e');
  }
}
```

### Step 8: Update Notification Handler in Flutter

**File:** `chatty/lib/common/utils/FirebaseMassagingHandler.dart`

Update `_receiveNotification` to handle contact notifications:

```dart
static Future<void> _receiveNotification(RemoteMessage message) async {
  print('[FCM] Received notification: ${message.data}');
  
  if (message.data == null) return;
  
  String? notificationType = message.data['type'];
  
  if (notificationType == 'contact_request') {
    // Handle contact request notification
    String senderName = message.data['sender_name'] ?? 'Someone';
    
    Get.snackbar(
      '📬 New Contact Request',
      '$senderName wants to connect with you',
      duration: Duration(seconds: 5),
      onTap: (_) {
        // Navigate to contacts page, requests tab
        Get.toNamed(AppRoutes.Contact, arguments: {'tab': 1});
      },
    );
  } 
  else if (notificationType == 'contact_accepted') {
    // Handle contact accepted notification
    String accepterName = message.data['accepter_name'] ?? 'Someone';
    String accepterToken = message.data['accepter_token'] ?? '';
    
    Get.snackbar(
      '✅ Request Accepted',
      '$accepterName accepted your contact request',
      duration: Duration(seconds: 5),
      onTap: (_) {
        // Navigate to chat with this person
        if (accepterToken.isNotEmpty) {
          Get.toNamed(AppRoutes.Contact);
        }
      },
    );
  }
  // ... existing code for call_type, messages, etc.
}
```

---

## 🧪 Testing Checklist

### 1. Test Contact Request Notification

**Steps:**
1. User A sends contact request to User B
2. User B's phone should receive notification
3. Tap notification → Opens contacts page (Requests tab)

**Check:**
- ✅ Notification appears on lock screen
- ✅ Notification shows sender name
- ✅ Tap opens correct screen

### 2. Test Contact Accepted Notification

**Steps:**
1. User B accepts User A's request
2. User A's phone should receive notification
3. Tap notification → Opens contacts page

**Check:**
- ✅ Notification appears
- ✅ Shows accepter name
- ✅ Tap opens app

### 3. Test Background/Killed State

**Steps:**
1. Close app completely (kill from recent apps)
2. Send contact request from another device
3. Check if notification arrives

**Expected:**
- ✅ Notification arrives even when app is killed
- ✅ Tap notification launches app
- ✅ Navigates to correct screen

---

## 🐛 Troubleshooting

### Problem: "FCM token is empty"
**Solution:** User needs to login first. FCM token is sent during login.

### Problem: "Failed to send notification"
**Check:**
1. Is `sakoa-64c2e-firebase-adminsdk-fbsvc-4abb13ca84.json` in correct location?
2. Is `.env` pointing to correct file?
3. Run: `php artisan config:clear` and `php artisan cache:clear`
4. Check Laravel logs: `storage/logs/laravel.log`

### Problem: Notification not appearing on phone
**Check:**
1. Is FCM token valid? (Check database: `users.fcmtoken`)
2. Firebase console → Cloud Messaging enabled?
3. App has notification permissions?
4. Try sending test from Firebase console first

### Problem: "Service account not found"
**Solution:**
```bash
cd chatty.codemain.top
ls -la sakoa-64c2e-firebase-adminsdk-fbsvc-4abb13ca84.json
# Should exist!
```

---

## 📝 Quick Test Commands

### 1. Test Firebase Connection
```bash
cd chatty.codemain.top
php artisan tinker
```

```php
$factory = (new \Kreait\Firebase\Factory)
    ->withServiceAccount(base_path('sakoa-64c2e-firebase-adminsdk-fbsvc-4abb13ca84.json'));
$messaging = $factory->createMessaging();
echo "Firebase connected!";
```

### 2. Send Test Notification
```php
$message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('token', 'YOUR_FCM_TOKEN')
    ->withNotification(\Kreait\Firebase\Messaging\Notification::create('Test', 'Hello from Laravel!'));
$messaging->send($message);
```

---

## 🚀 Next Steps

1. ✅ Create `FirebaseNotificationService.php`
2. ✅ Create `NotificationController.php`
3. ✅ Add routes in `routes/api.php`
4. ✅ Update Flutter `chat.dart` API
5. ✅ Update `ContactController` to send notifications
6. ✅ Update `FirebaseMassagingHandler.dart` to handle notifications
7. 🧪 Test on 2 physical devices!

---

**Ready to implement? I can create all the files for you! Just say "yes" and I'll start!** 🎉
