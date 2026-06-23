import 'package:chat_app/controller/login_controller.dart';
import 'package:chat_app/view/custom_snakbar.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final LoginController loginController = LoginController();

  bool isRegisterLoading = false;
  bool obscurePassword = true;

  // ================= SIGNUP FUNCTION =================
  Future<void> signUpData() async {

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {

      CustomSnackbar().showCustomSnackbar(
        context: context,
        message: "All fields are required",
      );
      return;
    }

    try {
      setState(() {
        isRegisterLoading = true;
      });

      String userId = await loginController.registerUser(
        context: context,
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userId.isEmpty) {
        setState(() {
          isRegisterLoading = false;
        });
        return;
      }

      await loginController.storeUserDataToDatabase(
        userData: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'profile_image': "",
          'userId': userId,
        },
      );

      nameController.clear();
      emailController.clear();
      passwordController.clear();

      setState(() {
        isRegisterLoading = false;
      });

      CustomSnackbar().showCustomSnackbar(
        context: context,
        message: "Account created successfully",
      );

      await Future.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {

      setState(() {
        isRegisterLoading = false;
      });

      String errorMessage =
          e.toString().replaceAll("Exception: ", "");

      CustomSnackbar().showCustomSnackbar(
        context: context,
        message: errorMessage,
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // Image
                Image.asset(
                  "asset/login.png",
                  width: MediaQuery.of(context).size.width * 0.5,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Fill the details below to get started",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 30),

                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Enter Name",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "Enter Email",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Enter Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Signup Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isRegisterLoading ? null : signUpData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                    ),
                    child: isRegisterLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
