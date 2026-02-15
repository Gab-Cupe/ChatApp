import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_form.dart';
import 'fadeInWidget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Variables para las frases
  List<String> _frases = [];
  String? _fraseActual;
  late AnimationController _fraseController;
  late Animation<double> _fraseAnimation;
  bool _frasesCargando = true;

  @override
  void initState() {
    super.initState();
    
    // Configurar animación para frases
    _fraseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fraseAnimation = CurvedAnimation(
      parent: _fraseController,
      curve: Curves.easeInOut,
    );
    
    _cargarFrases();
    _iniciarRotacionFrases();
  }

  Future<void> _cargarFrases() async {
    try {
      final ref = FirebaseDatabase.instance.ref('Frases');
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _frases = data.values.cast<String>().toList();
          _fraseActual = _frases.isNotEmpty ? _frases[0] : null;
          _frasesCargando = false;
        });
        _fraseController.forward();
      }
    } catch (e) {
      
      setState(() => _frasesCargando = false);
    }
  }

  void _iniciarRotacionFrases() {
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted || _frases.isEmpty) return;
      _cambiarFrase();
      _iniciarRotacionFrases();
    });
  }

  void _cambiarFrase() {
    _fraseController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _fraseActual = _frases[(DateTime.now().millisecondsSinceEpoch % _frases.length)];
      });
      _fraseController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double ancho = MediaQuery.of(context).size.width;
    final bool isMobile = ancho < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con imagen (responsivo)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isMobile ? 'assets/login/mobile.png' : 'assets/login/desktop.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Overlay semi-transparente
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // Contenido principal
          if (isMobile) 
            _buildMobileLayout()
          else 
            _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeInWidget(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWelcomeText(),
                const SizedBox(height: 40),
                const LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Panel lateral para frases (¡Aquí está la magia!)
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_frasesCargando)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_fraseActual != null)
                  FadeTransition(
                    opacity: _fraseAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: Colors.white.withOpacity(0.6),
                          size: 40,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _fraseActual!,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '- Sistema',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'No hay frases disponibles',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),

        // Formulario
        Expanded(
          flex: 3,
          child: Center(
            child: FadeInWidget(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(60),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildWelcomeText(),
                      const SizedBox(height: 40),
                      const LoginForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Bienvenido',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4DA8DA),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para continuar',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fraseController.dispose();
    super.dispose();
  }
}