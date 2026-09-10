import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'parent_panel.dart';

class ParentLoginPage extends StatefulWidget {
  const ParentLoginPage({super.key});

  @override
  State<ParentLoginPage> createState() => _ParentLoginPageState();
}

class _ParentLoginPageState extends State<ParentLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController =
  TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool hasPin = false;
  bool isLoading = true;

  bool obscurePin = true;
  bool obscureConfirmPin = true;

  bool isProcessing = false;
  bool showError = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    checkPin();
  }

  Future<void> checkPin() async {
    final prefs = await SharedPreferences.getInstance();

    final savedPin = prefs.getString('parent_pin');

    if (!mounted) return;

    setState(() {
      hasPin = savedPin != null && savedPin.isNotEmpty;
      isLoading = false;
    });

    _animationController.forward();
  }

  Future<void> createPin() async {
    FocusScope.of(context).unfocus();

    final pin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (pin.length != 4) {
      showMessage(
        'PIN 4 haneli olmalıdır.',
        isError: true,
      );
      return;
    }

    if (confirmPin.length != 4) {
      showMessage(
        'PIN tekrarını da 4 hane girin.',
        isError: true,
      );
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        showError = true;
      });

      HapticFeedback.mediumImpact();

      showMessage(
        'PIN kodları eşleşmiyor.',
        isError: true,
      );
      return;
    }

    setState(() {
      isProcessing = true;
      showError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('parent_pin', pin);

    if (!mounted) return;

    setState(() {
      hasPin = true;
      isProcessing = false;

      pinController.clear();
      confirmPinController.clear();
    });

    showMessage(
      'PIN başarıyla oluşturuldu.',
      isError: false,
    );
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final enteredPin = pinController.text.trim();

    if (enteredPin.length != 4) {
      showMessage(
        'Lütfen 4 haneli PIN girin.',
        isError: true,
      );
      return;
    }

    setState(() {
      isProcessing = true;
      showError = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('parent_pin');

    if (!mounted) return;

    if (savedPin == enteredPin) {
      HapticFeedback.mediumImpact();

      await Future.delayed(
        const Duration(milliseconds: 180),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration:
          const Duration(milliseconds: 450),
          pageBuilder: (
              context,
              animation,
              secondaryAnimation,
              ) =>
          const ParentPanel(),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      setState(() {
        isProcessing = false;
        showError = true;
      });

      HapticFeedback.heavyImpact();

      showMessage(
        'PIN yanlış. Tekrar deneyin.',
        isError: true,
      );
    }
  }

  void showMessage(
      String message, {
        required bool isError,
      }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFB96A7A)
            : const Color(0xFF23D83E),
        margin: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF9F4),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF23D83E),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // =====================================================
          // ARKA PLAN DEKORASYONLARI
          // =====================================================

          Positioned(
            top: -70,
            left: -55,
            child: _backgroundCircle(
              size: 190,
              color: const Color(0xFFD8FFDC),
            ),
          ),

          Positioned(
            top: -45,
            right: -60,
            child: _backgroundCircle(
              size: 185,
              color: const Color(0xFFDDF4FF),
            ),
          ),

          Positioned(
            bottom: -85,
            right: -45,
            child: _backgroundCircle(
              size: 190,
              color: const Color(0xFFDFFFE2),
            ),
          ),

          Positioned(
            bottom: -75,
            left: -70,
            child: _backgroundCircle(
              size: 150,
              color: const Color(0xFFFFE9F1),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // =====================================================
                // ÜST BAŞLIK
                // =====================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    0,
                  ),
                  child: Row(
                    children: [
                      _topButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      const Expanded(
                        child: Text(
                          'Ebeveyn Girişi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F7D38),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      const SizedBox(width: 46),
                    ],
                  ),
                ),

                // =====================================================
                // ANA İÇERİK
                // =====================================================

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics:
                      const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        24,
                        22,
                        30,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: double.infinity,
                            constraints:
                            const BoxConstraints(
                              maxWidth: 430,
                            ),
                            padding:
                            const EdgeInsets.fromLTRB(
                              22,
                              24,
                              22,
                              22,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.92),
                              borderRadius:
                              BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7653A8,
                                  ).withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset:
                                  const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // =================================================
                                // KİLİT İKONU
                                // =================================================

                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration:
                                  BoxDecoration(
                                    gradient:
                                    const LinearGradient(
                                      begin:
                                      Alignment.topLeft,
                                      end: Alignment
                                          .bottomRight,
                                      colors: [
                                        Color(0xFFD8FFDC),
                                        Color(0xFFDDF5FF),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7653A8,
                                        ).withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 16,
                                        offset:
                                        const Offset(
                                          0,
                                          7,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      hasPin
                                          ? '🔐'
                                          : '🔑',
                                      style:
                                      const TextStyle(
                                        fontSize: 40,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // =================================================
                                // BAŞLIK
                                // =================================================

                                Text(
                                  hasPin
                                      ? 'Ebeveyn Alanı'
                                      : 'Ebeveyn PIN Oluştur',
                                  textAlign:
                                  TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight:
                                    FontWeight.w900,
                                    color:
                                    Color(0xFF259242),
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 7),

                                Text(
                                  hasPin
                                      ? 'Zeka Bahçesi ayarlarına devam etmek için\\nPIN kodunu gir.'
                                      : 'Çocuk bölümünün ayarlarını korumak için\\n4 haneli bir PIN belirle.',
                                  textAlign:
                                  TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight:
                                    FontWeight.w500,
                                    color:
                                    Color(0xFF2CDD47),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // =================================================
                                // PIN BAŞLIK
                                // =================================================

                                Align(
                                  alignment:
                                  Alignment.centerLeft,
                                  child: Text(
                                    hasPin
                                        ? 'PIN Kodu'
                                        : 'Yeni PIN',
                                    style:
                                    const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w800,
                                      color:
                                      Color(0xFF279A45),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 7),

                                // =================================================
                                // PIN ALANI
                                // =================================================

                                _pinField(
                                  controller:
                                  pinController,
                                  obscureText:
                                  obscurePin,
                                  onToggle: () {
                                    setState(() {
                                      obscurePin =
                                      !obscurePin;
                                    });
                                  },
                                  hasError: showError,
                                  hintText:
                                  '4 haneli PIN',
                                ),

                                // =================================================
                                // PIN TEKRAR
                                // =================================================

                                if (!hasPin) ...[
                                  const SizedBox(height: 15),

                                  const Align(
                                    alignment:
                                    Alignment.centerLeft,
                                    child: Text(
                                      'PIN Tekrar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w800,
                                        color:
                                        Color(0xFF279A45),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  _pinField(
                                    controller:
                                    confirmPinController,
                                    obscureText:
                                    obscureConfirmPin,
                                    onToggle: () {
                                      setState(() {
                                        obscureConfirmPin =
                                        !obscureConfirmPin;
                                      });
                                    },
                                    hasError: showError,
                                    hintText:
                                    'PIN tekrar',
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // =================================================
                                // GİRİŞ / PIN OLUŞTUR BUTONU
                                // =================================================

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                    isProcessing
                                        ? null
                                        : hasPin
                                        ? login
                                        : createPin,
                                    style:
                                    ElevatedButton
                                        .styleFrom(
                                      elevation: 0,
                                      backgroundColor:
                                      const Color(
                                        0xFF7653A8,
                                      ),
                                      disabledBackgroundColor:
                                      const Color(
                                        0xFFB9A6D0,
                                      ),
                                      foregroundColor:
                                      Colors.white,
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          18,
                                        ),
                                      ),
                                    ),
                                    child: isProcessing
                                        ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth:
                                        2.5,
                                        color:
                                        Colors.white,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        Icon(
                                          hasPin
                                              ? Icons
                                              .login_rounded
                                              : Icons
                                              .lock_open_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Text(
                                          hasPin
                                              ? 'Giriş Yap'
                                              : 'PIN Oluştur',
                                          style:
                                          const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight
                                                .w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // =================================================
                                // ALT BİLGİ
                                // =================================================

                                Container(
                                  width: double.infinity,
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration:
                                  BoxDecoration(
                                    color: const Color(
                                      0xFFF6F0FB,
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .security_rounded,
                                        size: 18,
                                        color: Color(
                                          0xFF7653A8,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 9,
                                      ),
                                      Expanded(
                                        child: Text(
                                          hasPin
                                              ? 'PIN kodunuz yalnızca bu cihazda saklanır.'
                                              : 'PIN kodunuzu kimseyle paylaşmayın.',
                                          style:
                                          const TextStyle(
                                            fontSize: 11,
                                            height: 1.35,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: Color(
                                              0xFF776A7A,
                                            ),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // PIN FIELD
  // =====================================================

  Widget _pinField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required bool hasError,
    required String hintText,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFFFFF1F3)
            : const Color(0xFFE6FAE8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? const Color(0xFFD47A7A)
              : const Color(0xFFD9F4DC),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: TextInputType.number,
        maxLength: 4,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (_) {
          if (showError) {
            setState(() {
              showError = false;
            });
          }
        },
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
          color: Color(0xFF259242),
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: Color(0xFF73E884),
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            tooltip: obscureText
                ? "PIN'i göster"
                : "PIN'i gizle",
            icon: Icon(
            obscureText
            ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: const Color(0xFF39DF52),
            size: 21,
          ),
        ),
      ),
    ),
    );
  }

  // =====================================================
  // ÜST BUTON
  // =====================================================

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF23D83E)
                  .withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 19,
          color: const Color(0xFF279A45),
        ),
      ),
    );
  }

  // =====================================================
  // ARKA PLAN DAİRESİ
  // =====================================================

  Widget _backgroundCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
    );
  }
}