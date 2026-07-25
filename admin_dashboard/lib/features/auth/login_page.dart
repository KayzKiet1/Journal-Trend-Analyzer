import 'package:flutter/material.dart';

import '../../app/router.dart';
import 'login_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialError});

  final String? initialError;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _viewModel = LoginViewModel();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEEF2FF),
                  Color(0xFFE0E7FF),
                ],
              ),
            ),
          ),
          
          // Decorative Abstract Shapes
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.05,
            child: _buildBlurCircle(size.width * 0.4, const Color(0xFF6366F1).withOpacity(0.08)),
          ),
          Positioned(
            bottom: -size.height * 0.2,
            right: -size.width * 0.1,
            child: _buildBlurCircle(size.width * 0.5, const Color(0xFF818CF8).withOpacity(0.1)),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Panel: Vibrant Brand Gradient
                          if (size.width >= 850)
                            Expanded(
                              flex: 12,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    stops: [0.1, 0.6, 0.9],
                                    colors: [
                                      Color(0xFF1E1B4B), // Indigo 950
                                      Color(0xFF0F172A), // Slate 900
                                      Color(0xFF1E293B), // Slate 800
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(56),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBrandLogo(),
                                    const Spacer(),
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Colors.white, Color(0xFFC7D2FE)],
                                      ).createShader(bounds),
                                      child: Text(
                                        'Quản trị dữ liệu\nnghiên cứu thông minh.',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          height: 1.1,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Cung cấp cái nhìn toàn cảnh về xu hướng tạp chí và ấn phẩm khoa học toàn cầu.',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    ),
                                    const Spacer(),
                                    _buildFeatureItem(Icons.auto_graph_rounded, 'Phân tích xu hướng thời gian thực'),
                                    _buildFeatureItem(Icons.verified_user_rounded, 'Kiểm soát truy cập Claim-based'),
                                    _buildFeatureItem(Icons.shield_rounded, 'Bảo mật dữ liệu chuẩn Enterprise'),
                                  ],
                                ),
                              ),
                            ),

                          // Right Panel: Clean Form
                          Expanded(
                            flex: 11,
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(size.width >= 850 ? 64 : 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (size.width < 850) _buildBrandLogo(dark: false),
                                  if (size.width < 850) const SizedBox(height: 48),
                                  
                                  const Text(
                                    'Đăng nhập Admin',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Vui lòng nhập thông tin xác thực để tiếp tục.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                                  ),
                                  const SizedBox(height: 48),
                                  
                                  _buildForm(),
                                  
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 24),
                                    _buildErrorBanner(_errorMessage!),
                                  ],
                                  
                                  const SizedBox(height: 40),
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double radius, Color color) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildBrandLogo({bool dark = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          'Journal Admin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: dark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF818CF8), size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'admin@journal.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (v) => (v?.contains('@') ?? false) ? null : 'Email không hợp lệ',
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isBusy = _isLoading || _isGoogleLoading;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isBusy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Đăng nhập hệ thống'),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('HOẶC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: isBusy ? null : _signInWithGoogle,
          icon: _isGoogleLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.login)),
          label: const Text('Tiếp tục với Google Workspace'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF9F1239), fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final ok = await _viewModel.signInAsAdmin(email: _emailController.text, password: _passwordController.text);
      if (!mounted) return;
      if (!ok) {
        setState(() => _errorMessage = 'Tài khoản không có quyền Admin.');
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(AdminRoutes.dashboard, (route) => false);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isGoogleLoading = true; _errorMessage = null; });
    try {
      final ok = await _viewModel.signInWithGoogleAsAdmin();
      if (!mounted) return;
      if (!ok) {
        setState(() => _errorMessage = 'Tài khoản Google này không có quyền Admin.');
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(AdminRoutes.dashboard, (route) => false);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
}
