# 🔐 Authentication Debugging Guide

## What Changed

I've improved the error messages to show you **exactly** what went wrong:

### Before
```
❌ "Authentication failed. Check your credentials."
```

### Now
```
❌ "No account found with this email"
OR
❌ "Incorrect password"
OR
❌ Network error. Check your internet connection
```

---

## Common Authentication Errors & Fixes

### 1. **"No account found with this email"**
**Problem:** The email doesn't exist in Firebase  
**Solution:**  
- Use "Sign Up" button first to create account
- Check email spelling is correct
- Make sure you're using the same email

### 2. **"Incorrect password"**
**Problem:** Password is wrong  
**Solution:**  
- Passwords are case-sensitive
- Check Caps Lock is off
- Try Password must contain: at least 6 characters, mix of letters, numbers, symbols recommended

### 3. **"This email is already registered"**
**Problem:** Email already has an account  
**Solution:**  
- Click "Already have account? Login" to sign in instead
- Use different email to create new account

### 4. **"Password must be at least 6 characters"**
**Problem:** Password too short  
**Solution:**  
- Use at least 6 characters
- Example: `Test@123` (8 characters)

### 5. **"Invalid email address"**
**Problem:** Email format is wrong  
**Solution:**  
- Check format: `user@example.com`
- No spaces allowed
- Must have @ symbol

### 6. **"Network error. Check your internet connection"**
**Problem:** Can't reach Firebase  
**Solution:**  
- Check internet connection
- Try refreshing page (F5)
- Check if Firebase is down (rare)
- Check browser console for CORS errors

### 7. **"Too many login attempts"**
**Problem:** Too many failed logins  
**Solution:**  
- Wait 5-10 minutes
- Or reset your password in Firebase Console

---

## How to See Detailed Error Messages

### On Chrome Browser:

1. **Open Chrome DevTools:**
   - Press `F12` or `Right-click → Inspect`

2. **Go to Console tab:**
   - Click on "Console" tab at top

3. **Try to authenticate:**
   - Attempt login/signup in app
   - Watch the Console for detailed errors

4. **Look for patterns:**
   ```
   ✅ Success: "SignIn successful: test@example.com"
   ❌ Error: "Auth Error (SignIn): user-not-found - No account found with this email"
   ```

---

## Test Credentials to Try

### Create New Account (Sign Up)
```
Email: mytest@example.com
Password: Test@123456
```
✅ Should show: "Sign up successful"

### Sign In (Login)
```
Email: mytest@example.com
Password: Test@123456
```
✅ Should redirect to Home page

### Try Wrong Password
```
Email: mytest@example.com
Password: WrongPassword
```
❌ Should show: "Incorrect password"

---

## Firebase Setup Check

**Your Firebase Project:** `gen-lang-client-0543931071`

To verify Firebase is working:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `gen-lang-client-0543931071`
3. Go to **Authentication → Users**
4. You should see users you create here
5. Go to **Firestore Database**
6. Check `users` collection for user profiles

---

## Complete Login/Signup Flow

```
┌─────────────────────────────────────┐
│  Auth Page                          │
│  [Email Input]                      │
│  [Password Input]                   │
│  [Sign Up / Login Button]           │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Validate Input                     │
│  • Email not empty? ✓               │
│  • Password not empty? ✓            │
│  • Email valid format? ✓            │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  Firebase Authentication            │
│  • Check credentials ✓              │
│  • Return credential or error       │
└─────────────────────────────────────┘
           ↓
      Sign Up Only ↓
┌─────────────────────────────────────┐
│  Create Firestore User Profile      │
│  • Save user data ✓                 │
│  • (OK if this fails - still auth) │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  ✅ Authentication Success!         │
│  → Navigate to Home Page            │
└─────────────────────────────────────┘
```

---

## Troubleshooting Checklist

- [ ] Email is in valid format (user@example.com)
- [ ] Password is at least 6 characters
- [ ] No extra spaces before/after email
- [ ] Internet connection working
- [ ] Using same email for login that was used to sign up
- [ ] Browser console shows success message
- [ ] User appears in Firebase Console → Authentication

---

## Quick Test Commands

```powershell
# Run app and watch console
cd "C:\Users\vedan\OneDrive\Desktop\AIhealth\AI-Health-Assistent"
flutter run -d chrome

# Then in browser:
# 1. Press F12
# 2. Go to Console tab
# 3. Try to sign up new account
# 4. Watch for error messages
```

---

## Still Having Issues?

Check the VS Code Debug Console for detailed error logs:

1. Run: `flutter run -d chrome`
2. Look for logs starting with: `Auth Error (SignUp):` or `Auth Error (SignIn):`
3. Share the exact error code from logs

**Common error codes:**
- `user-not-found` → Email doesn't exist
- `wrong-password` → Password incorrect
- `email-already-in-use` → Email already has account
- `weak-password` → Password too short
- `invalid-email` → Email format wrong

---

**Status:** ✅ Enhanced error messages active  
**Last Updated:** March 19, 2026
