import 'package:articulicare/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:articulicare/components/my_button.dart';
import 'package:articulicare/components/my_textfield.dart';
import 'package:articulicare/components/square_tile.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Editing controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // For toggling password visibility
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // User sign-up method
  void signUserUp() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        // Ensure passwords match
        if (passwordController.text == confirmPasswordController.text) {
          // Create user in Firebase
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
          Navigator.pop(context);
          User? user = userCredential.user;
          if (user != null) {
            await user.updateDisplayName(usernameController.text);
            await user.reload();
          }

        } else {
          Navigator.pop(context);
          showErrorMessage("Passwords do not match");
        }
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        showErrorMessage(e.message ?? "An error occurred");
      }
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
void Betaversion_showDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: Text('Beta Version'),
      content: Text('login with Apple id is not possible at the moment',),
      actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                child: Text('OK', style: TextStyle(color: Colors.blue),),
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
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 15.h),
                  Container(
                    height: 220.h,
                    width: 220.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/splash_logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 25.h),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 20.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 25.h),
                  // Username field
                  MyTextfield(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                  validator: (value) {
                    // Check if the value is null or empty
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    // Check if the value is zero, negative, or variations like "-0"
                    else if (RegExp(r'^-?0+$').hasMatch(value.trim()) || RegExp(r'^-\d+$').hasMatch(value.trim())) {
                      return 'Username cannot be zero or negative';
                    }
                    // Check if the value contains only digits
                    else if (RegExp(r'^\d+$').hasMatch(value.trim())) {
                      return 'Username cannot contain only digits';
                    }
                    // Check if the value contains any special characters
                    else if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value.trim())) {
                      return 'Username cannot contain special characters';
                    }
                    // Check minimum length of 3
                    else if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null; // Validation passed
                  },
                ),
                SizedBox(height: 10.h),
                  // Email field
                  MyTextfield(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  // Password field
                  MyTextfield(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: !isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      } else if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.h),
                  // Confirm password field
                  MyTextfield(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: !isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 25.h),
                  // Sign-up button
                  MyButton(
                    text: 'Sign Up',
                    onTap: signUserUp,
                  ),
                  SizedBox(height: 30.h),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have Account?",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          "Login Now",
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
