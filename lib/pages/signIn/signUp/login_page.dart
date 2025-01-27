import 'package:articulicare/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:articulicare/components/my_button.dart';
import 'package:articulicare/components/square_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../components/my_textfield.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isPasswordVisible = false; 

  void signUserIn() async {
    if (formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        showErrorMessage(e.code);
      }
    }
  }

 void _showForgotPasswordDialog() {
  final resetEmailController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Reset Password',
          style: TextStyle(fontSize: 18.sp, color: Colors.blue),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                  ),
                  border: OutlineInputBorder(), // Default border if none of the above are active
                ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _resetPassword(resetEmailController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.blue) ,),
          ),
        ],
      );
    },
  );
}


void _resetPassword(String email) async {
  if (email.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid email address.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset link sent to $email.'),
        backgroundColor: Colors.green,
      ),
    );
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blue.shade400,
          title: Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
          ),
        );
      },
    );
  }

  //function to show dialog box
void Betaversion_showDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: const Text('Beta Version'),
      content: const Text('login with Apple id is not possible at the moment',),
      actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                child: const Text('OK', style: TextStyle(color: Colors.blue),),
              ),
            ],
          );         
        },
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 15.h),
                    Container(
                    height: 230.h, 
                    width: 230.h,  
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, 
                      image: DecorationImage(
                        image: AssetImage('assets/images/splash_logo.png'),
                        fit: BoxFit.cover, 
                      ),
                    ),
                  ),

                  SizedBox(height: 25.h),
                  Text(
                    'ArticuliCare',
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 25.h),
                  
                  // Email TextField
                  MyTextfield(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Password TextField
                  MyTextfield(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Forgot Password
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                  InkWell(
                    onTap: () {
                          _showForgotPasswordDialog();
                        },
 
                    hoverColor: Colors.blue.withOpacity(0.2), 
                    child: Text(
                      "Forgot password?",
                        style: TextStyle(
                          color: Colors.grey[600],
                          decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  SizedBox(height: 25.h),
                  
                  // Continue Button
                  MyButton(
                    text: 'Continue',
                    onTap: signUserIn,
                  ),
                  SizedBox(height: 30.h),
                  
                  // Or Continue with
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            "Or Continue with",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  
                  // Google and Apple Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: "assets/images/google.png",
                      ),
                      SizedBox(width: 25.w),
                      SquareTile(
                        onTap: () {
                          Betaversion_showDialog();
                        },
                        imagePath: "assets/images/apple.png",
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  
                  // Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not a member?",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
