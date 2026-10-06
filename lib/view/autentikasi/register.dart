import 'package:absensi/service/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:absensi/model/register_model.dart';
import 'package:absensi/service/api_service.dart';
import 'package:absensi/view/autentikasi/login.dart';

// import 'package:absensi/pages/index.dart'; // Index

/// Halaman pendaftaran (registrasi) akun baru melalui API.
class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _registrasiForm = GlobalKey<FormState>();
  final _inpFullNameRegister = TextEditingController();
  final _inpEmailRegister = TextEditingController();
  final _inpPassRegister = TextEditingController();

  // true = password disamarkan
  bool obsecure = true;
  bool _isLoading = false;

  static const Color _primaryColor = Color.fromARGB(255, 17, 35, 95);

  /// Menampilkan snackbar dengan aman.
  void _showSnack(String message, {Color? color, int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  /// Memproses data registrasi user.
  Future<void> _simpanPendaftaranUser() async {
    if (!_registrasiForm.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dio = createDioService();
    final apiService = ApiService(dio);

    final registerData = RegisterModel(
      name: _inpFullNameRegister.text.trim(),
      email: _inpEmailRegister.text.trim(),
      password: _inpPassRegister.text,
    );

    try {
      final RegisterModel response = await apiService.registerUser(
        registerData,
      );
      debugPrint('RESPONSE: ${response.toJson()}');
      if (!mounted) return;

      _showSnack(
        response.message ?? 'Registrasi berhasil, silakan login.',
        color: Colors.green,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } on DioException catch (e) {
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('BODY: ${e.response?.data}');
      String errorMessage = 'Terjadi kesalahan pada koneksi internet';

      final responseData = e.response?.data;
      if (responseData is Map) {
        final errors = responseData['errors'];
        if (errors is Map) {
          final semuaError = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              semuaError.addAll(value.map((item) => item.toString()));
            }
          });
          if (semuaError.isNotEmpty) {
            errorMessage = semuaError.join('\n');
          }
        } else {
          errorMessage = responseData['message']?.toString() ?? errorMessage;
        }
      }

      _showSnack('Error: $errorMessage', color: Colors.red, seconds: 5);
    } catch (e) {
      _showSnack('Error: $e', color: Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _inpFullNameRegister.dispose();
    _inpEmailRegister.dispose();
    _inpPassRegister.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Register',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _registrasiForm,
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please fill in the details below to \n create a new account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(), // dorong container ke bawah
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        const SizedBox(height: 40),

                        // NAMA
                        TextFormField(
                          controller: _inpFullNameRegister,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama wajib diisi';
                            } else if (value.trim().length < 3) {
                              return 'Nama minimal 3 karakter';
                            } else if (!RegExp(r'^[a-zA-Z\s]+$')
                                .hasMatch(value)) {
                              return 'Nama hanya boleh berisi huruf';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'Masukkan nama',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // EMAIL
                        TextFormField(
                          controller: _inpEmailRegister,
                          keyboardType: TextInputType.emailAddress,
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
                          controller: _inpPassRegister,
                          obscureText: obsecure,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            } else if (value.length < 6) {
                              return 'Password minimal 6 karakter';
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
                        const SizedBox(height: 24),

                        // BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                            ),
                            onPressed: _isLoading
                                ? null
                                : _simpanPendaftaranUser,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'already have an account?',
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
                                      builder: (context) => const Login(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign in',
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
