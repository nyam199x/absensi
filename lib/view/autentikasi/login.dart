import 'package:absensi/view/dashboard/dashboard.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide Image;

import 'package:absensi/view/autentikasi/register.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:absensi/service/dio_service.dart';
import 'package:absensi/service/api_service.dart';

class Login extends StatefulWidget {
  final bool showLogoutMessage;

  const Login({super.key, this.showLogoutMessage = false});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool obsecure = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Controller form
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // Focus untuk animasi
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  // Controller API
  late final ApiService _apiService = ApiService(createDioService());

  // Rive controller dan input
  StateMachineController? controller;

  SMIBool? lookOnEmail;
  SMINumber? followOnEmail;

  SMIBool? lookOnPassword;
  SMIBool? peekOnPassword;

  SMITrigger? triggerSuccess;
  SMITrigger? triggerFail;

  @override
  void initState() {
    super.initState();

    emailFocusNode.addListener(() {
      lookOnEmail?.change(emailFocusNode.hasFocus);
    });

    passwordFocusNode.addListener(() {
      lookOnPassword?.change(passwordFocusNode.hasFocus);
    });

    if (widget.showLogoutMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil Logout'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();

    emailController.dispose();
    passwordController.dispose();

    emailFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      triggerFail?.fire();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiService.login({
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      debugPrint('LOGIN: $res');

      final data = res is Map ? (res['data'] ?? res) : null;

      final token = data is Map
          ? (data['token'] ?? data['access_token'])?.toString()
          : null;

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan di respons login');
      }

      final user = data is Map ? data['user'] : null;
      final name = user is Map ? user['name']?.toString() : null;

      await SimpanToken.saveSession(token: token, name: name);

      if (!mounted) return;

      // Jalankan animasi berhasil
      triggerSuccess?.fire();

      // Beri waktu agar animasi berhasil terlihat
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } on DioException catch (e) {
      triggerFail?.fire();

      final body = e.response?.data;

      final pesan = body is Map && body['message'] != null
          ? body['message'].toString()
          : 'Login gagal, periksa email dan password';

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pesan)));
    } catch (e) {
      triggerFail?.fire();

      debugPrint('Error login: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat login')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // final double _rasioArtboard = 1.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 35, 95),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 17, 35, 95),
        centerTitle: true,
        title: const Text(
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ANIMASI RIVE DI BAWAH APPBAR
              // Expanded(
              //   child: LayoutBuilder(
              //     builder: (context, constraints) {
              //       final tinggiTampil = (constraints.maxWidth / _rasioArtboard)
              //           .clamp(0.0, constraints.maxHeight);

              //       return Transform.translate(
              //         offset: Offset(0, tinggiTampil * 0.08),
              //         child: RiveAnimation.asset(
              //           'assets/animations/auth_teddy.riv',
              //           fit: BoxFit.contain,
              //           onInit: (artboard) {
              //             final riveController =
              //                 StateMachineController.fromArtboard(
              //                   artboard,
              //                   'Login Machine',
              //                 );

              //             if (riveController == null) {
              //               debugPrint(
              //                 'State machine Login Machine tidak ditemukan',
              //               );
              //               return;
              //             }

              //             artboard.addController(riveController);
              //             controller = riveController;

              //             lookOnEmail = riveController.getBoolInput('isFocus');

              //             followOnEmail = riveController.getNumberInput(
              //               'numLook',
              //             );

              //             lookOnPassword = riveController.getBoolInput(
              //               'isPrivateField',
              //             );

              //             peekOnPassword = riveController.getBoolInput(
              //               'isPrivateFieldShow',
              //             );

              //             triggerSuccess = riveController.getTriggerInput(
              //               'successTrigger',
              //             );

              //             triggerFail = riveController.getTriggerInput(
              //               'failTrigger',
              //             );

              //             // Sinkronkan animasi dengan fokus saat ini
              //             lookOnEmail?.change(emailFocusNode.hasFocus);

              //             lookOnPassword?.change(passwordFocusNode.hasFocus);

              //             peekOnPassword?.change(!obsecure);
              //           },
              //         ),
              //       );
              //     },
              //   ),
              // ),
              const SizedBox(height: 40),
              // FORM LOGIN
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(70),
                      topRight: Radius.circular(70),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),

                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Hello Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 17, 35, 95),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Welcome back please\nsign in again',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // EMAIL
                        TextFormField(
                          controller: emailController,
                          focusNode: emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            followOnEmail?.change(value.length.toDouble());
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email wajib diisi';
                            } else if (!value.contains('@')) {
                              return 'Format email tidak valid';
                            }

                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Masukkan email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD
                        TextFormField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          obscureText: obsecure,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }

                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Masukkan password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obsecure = !obsecure;
                                  peekOnPassword?.change(!obsecure);
                                });
                              },
                              icon: Icon(
                                obsecure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TOMBOL LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                17,
                                35,
                                95,
                              ),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // PEMISAH
                        // Row(
                        //   children: [
                        //     const Expanded(
                        //       child: Padding(
                        //         padding: EdgeInsets.only(left: 10),
                        //         child: Divider(
                        //           color: Colors.black,
                        //           thickness: 1,
                        //         ),
                        //       ),
                        //     ),

                        //     const Padding(
                        //       padding: EdgeInsets.symmetric(
                        //         horizontal: 20,
                        //       ),
                        //       child: Text(
                        //         'or',
                        //         style: TextStyle(
                        //           color: Colors.black,
                        //           fontWeight: FontWeight.bold,
                        //           fontSize: 20,
                        //         ),
                        //       ),
                        //     ),

                        //     const Expanded(
                        //       child: Padding(
                        //         padding: EdgeInsets.only(right: 10),
                        //         child: Divider(
                        //           color: Colors.black,
                        //           thickness: 1,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        // const SizedBox(height: 10),

                        // // FACEBOOK
                        // Container(
                        //   width: double.infinity,
                        //   height: 45,
                        //   decoration: BoxDecoration(
                        //     color: const Color.fromARGB(255, 17, 35, 95),
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         'assets/iconfb.png',
                        //         width: 30,
                        //         height: 30,
                        //       ),
                        //       const SizedBox(width: 6),
                        //       const Text(
                        //         'Facebook',
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           color: Colors.white,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // const SizedBox(height: 10),

                        // // GOOGLE
                        // Container(
                        //   width: double.infinity,
                        //   height: 45,
                        //   decoration: BoxDecoration(
                        //     color: const Color.fromARGB(255, 17, 35, 95),
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         'assets/search.png',
                        //         width: 30,
                        //         height: 20,
                        //       ),
                        //       const SizedBox(width: 10),
                        //       const Text(
                        //         'Google',
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           color: Colors.white,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // LINK REGISTER
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Dont have an account?',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(width: 5),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Register(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 17, 35, 95),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
