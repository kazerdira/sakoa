# 🐛 Contact Loading Debug Guide

## Issue: Contacts Not Showing in UI

### What We Fixed:

1. **Removed `orderBy` clause** that required Firestore index
   - Changed from: `.orderBy("accepted_at", descending: true)`
   - To: No orderBy (simpler query, no index needed)
   
2. **Added comprehensive debug logging** to track data flow

3. **Added `debugCheckFirestoreData()`** method to verify data

---

## 📊 How to Debug:

### Step 1: Hot Reload the App
```bash
# In VS Code terminal or Flutter console
r  # Hot reload
```

### Step 2: Check Console Logs

After opening the Contacts page, look for these log messages:

#### A. **Debug Check Output:**
```
========================================
[ContactController] 🔍 DEBUG: Checking Firestore data
[ContactController] 🔍 My token: <your_token>
[ContactController] 📊 Total contacts where I'm user: X
   - Status: accepted, Contact: John Doe
[ContactController] 📊 Total contacts where I'm contact: Y
   - Status: accepted, User: Jane Smith
[ContactController] 👤 My profile: Your Name (online: 1)
========================================
```

#### B. **Loading Contacts Output:**
```
[ContactController] 📥 Loading accepted contacts for token: <your_token> (Page size: 20)
[ContactController] 📊 Found X outgoing + Y incoming
[ContactController] 🔍 Sample outgoing: {user_token: ..., contact_token: ..., status: accepted}
[ContactController] 🔍 Batch fetching Z user profiles...
[ContactController] 🔍 Tokens to fetch: [token1, token2, ...]
[ContactController] 📦 Got N profiles from batch
[ContactController] ✅ Cached profile: John Doe (token123)
[ContactController] ✅ Loaded M unique contacts | Total: M | Has more: false
```

---

## 🔍 Common Issues & Solutions:

### Issue 1: "Total contacts: 0"
**Problem:** No accepted contacts in Firestore
**Solution:** 
1. Search for a user
2. Send contact request
3. Have them accept (or accept their request)
4. Check logs again

### Issue 2: "Profile not found for X"
**Problem:** Contact exists but user profile doesn't
**Solution:**
1. User needs to login at least once (creates user_profile)
2. Check if `user_profiles` collection exists in Firestore
3. Verify token matches between `contacts` and `user_profiles`

### Issue 3: "No tokens to fetch"
**Problem:** Query returned 0 results
**Possible Causes:**
- Contacts have status != "accepted"
- Token mismatch (using wrong token)
- Firestore rules blocking reads

**Check Firestore Rules:**
```javascript
match /contacts/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}

match /user_profiles/{document} {
  allow read: if request.auth != null;
  allow write: if request.auth != null;
}
```

### Issue 4: "Permission denied"
**Problem:** Firestore security rules blocking access
**Solution:**
1. Check Firebase Console → Firestore → Rules
2. Verify user is authenticated (logged in)
3. Temporarily add debug rule (for testing only):
```javascript
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

---

## 🧪 Manual Test Procedure:

### Test 1: Create Accepted Contact
1. Login as User A
2. Go to Contacts → Search
3. Search for User B by name
4. Click "+ Add" to send request
5. Logout, login as User B
6. Go to Contacts → Requests tab
7. Click "✓ Accept"
8. Check Contacts tab → Should see User A

### Test 2: Bidirectional Contact
1. User A sends request to User B
2. User B accepts
3. Check Firestore Console:
```
contacts/
  doc1: {user_token: A, contact_token: B, status: "accepted"}
```
4. User A should see User B in Contacts tab
5. User B should see User A in Contacts tab

### Test 3: Online Status
1. User A is online (online: 1 in user_profiles)
2. User B opens Contacts tab
3. User A should have **green dot** 🟢
4. User A logs out (should set online: 0)
5. User B refreshes → User A should have **grey dot** ⚫

---

## 📱 Firestore Data Structure Check:

### Expected Structure:

#### `contacts` collection:
```javascript
{
  "user_token": "token_of_requester",
  "contact_token": "token_of_target",
  "user_name": "Requester Name",
  "user_avatar": "https://...",
  "user_online": 1,
  "contact_name": "Target Name",
  "contact_avatar": "https://...",
  "contact_online": 1,
  "status": "accepted",  // ← MUST be "accepted"
  "requested_by": "token_of_requester",
  "requested_at": Timestamp,
  "accepted_at": Timestamp  // ← Optional but recommended
}
```

#### `user_profiles` collection:
```javascript
{
  "token": "user_access_token",  // ← Document ID
  "name": "John Doe",
  "avatar": "https://...",
  "email": "john@example.com",
  "online": 1,  // ← 1=online, 0=offline
  "search_name": "john doe",
  "updated_at": Timestamp
}
```

---

## 🔧 Quick Fixes:

### Fix 1: Force Reload Contacts
Add this button to UI temporarily:
```dart
ElevatedButton(
  onPressed: () {
    controller.loadAcceptedContacts(refresh: true);
  },
  child: Text("Force Reload Contacts"),
)
```

### Fix 2: Check Token
Add to debug output:
```dart
print("My token: ${UserStore.to.token}");
print("Profile token: ${UserStore.to.profile.token}");
```
**They should be the SAME!**

### Fix 3: Verify Firestore Auth
```dart
final user = FirebaseAuth.instance.currentUser;
print("Firebase user: ${user?.uid}");
print("Is authenticated: ${user != null}");
```

---

## 📈 Performance Metrics:

### Expected Load Times:
- **0 contacts:** ~100ms (query returns empty)
- **1-20 contacts:** ~300-500ms (1 query + profile fetch)
- **21-40 contacts:** ~600-800ms (2 batches)
- **100+ contacts:** ~2-3s (pagination kicks in)

### Firestore Read Counts:
- **First load:** 2 queries (contacts) + N/10 queries (profiles)
- **Cached load:** 2 queries (contacts) + 0 queries (cached profiles)
- **Example:** 15 contacts = 2 + 2 = 4 reads (efficient!)

---

## ✅ Success Indicators:

You'll know it's working when you see:

1. **Console logs show:**
   ```
   [ContactController] ✅ Loaded 5 unique contacts | Total: 5 | Has more: false
   ```

2. **Contacts tab shows:**
   - List of accepted friends
   - Green/grey dots for online status
   - Avatar images
   - Names displayed correctly

3. **Pull-to-refresh works:**
   - Swipe down → Shows loading spinner
   - Releases → Reloads contacts

4. **Tap contact → Opens chat:**
   - No "must be contacts" error
   - Chat screen opens successfully

---

## 🆘 If Still Not Working:

1. **Check Firebase Console:**
   - Firestore → `contacts` collection
   - Look for documents with `status: "accepted"`
   - Verify `user_token` and `contact_token` match your token

2. **Check Flutter logs:**
   - Look for errors mentioning "PERMISSION_DENIED"
   - Look for "Profile not found" warnings
   - Check if token is null or empty

3. **Verify authentication:**
   ```dart
   print("Logged in: ${UserStore.to.isLogin}");
   print("Token: ${UserStore.to.token}");
   ```

4. **Test with Firestore Console:**
   - Manually add a test contact with status "accepted"
   - Refresh app → Should appear

5. **Check network connectivity:**
   - Ensure phone/emulator can reach Firestore
   - Check for offline mode issues

---

## 📞 Next Steps:

After hot reload, **copy and paste the console logs** here so we can see:
1. Total contacts found
2. Whether profiles are being fetched
3. Any errors or warnings

This will help us pinpoint exactly what's happening! 🎯
