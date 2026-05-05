import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/quotes_data.dart';
import '../models/quote.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with TickerProviderStateMixin {
  late Quote _currentQuote;
  final Random _random = Random();
  bool _isFavorited = false;
  bool _isCopied = false;
  bool _isShared = false;
  int _quoteCount = 1;

  late AnimationController _fadeController;
  late AnimationController _buttonController;
  late AnimationController _cardController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _pulseAnimation;

  int? _lastIndex;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
      lowerBound: 0.93,
      upperBound: 1.0,
    )..value = 1.0;
    _buttonScaleAnimation = _buttonController;

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pickRandomQuote(animate: false);
    _fadeController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _pickRandomQuote({bool animate = true}) {
    int newIndex;
    do {
      newIndex = _random.nextInt(allQuotes.length);
    } while (newIndex == _lastIndex && allQuotes.length > 1);

    _lastIndex = newIndex;

    if (animate) {
      _fadeController.reset();
      _cardController.reset();
      setState(() {
        _currentQuote = allQuotes[newIndex];
        _isFavorited = false;
        _isCopied = false;
        _isShared = false;
        _quoteCount++;
      });
      _fadeController.forward();
      _cardController.forward();
    } else {
      _currentQuote = allQuotes[newIndex];
    }
  }

  Future<void> _onNewQuote() async {
    HapticFeedback.lightImpact();
    await _buttonController.reverse();
    _buttonController.forward();
    _pickRandomQuote();
  }

  void _onCopy() {
    HapticFeedback.selectionClick();
    Clipboard.setData(
      ClipboardData(
        text: '"${_currentQuote.text}" — ${_currentQuote.author}',
      ),
    );
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _onShare() {
    HapticFeedback.selectionClick();
    final text = '"${_currentQuote.text}"\n\n— ${_currentQuote.author}\n\n✨ Daily Quotes App';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _isShared = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Copied to share!',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isShared = false);
    });
  }

  Color _categoryColor(String category) {
    const Map<String, Color> colors = {
      'Motivation': Color(0xFFFF6B6B),
      'Wisdom': Color(0xFF4ECDC4),
      'Life': Color(0xFFFFBE0B),
      'Dreams': Color(0xFFA78BFA),
      'Perseverance': Color(0xFFFF9F43),
      'Success': Color(0xFF26D0CE),
      'Mindset': Color(0xFF74B9FF),
      'Humor': Color(0xFFFD79A8),
      'Philosophy': Color(0xFF81ECEC),
      'Love': Color(0xFFFF7675),
      'Creativity': Color(0xFFFDCB6E),
    };
    return colors[category] ?? const Color(0xFF6C5CE7);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(_currentQuote.category);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity!.abs() > 200) {
            _onNewQuote();
          }
        },
        child: Stack(
          children: [
            // Animated background blobs
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -80,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              categoryColor.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -120,
                    left: -100,
                    child: Transform.scale(
                      scale: 2.05 - _pulseAnimation.value,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              categoryColor.withOpacity(0.10),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.4,
                    left: size.width * 0.3,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6C5CE7).withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // ── Top AppBar ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Row(
                      children: [
                        // App icon + name
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFFA78BFA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '❝',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Quotes',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Inspire your day',
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Quote counter badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: categoryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '#$_quoteCount of ${allQuotes.length}',
                            style: GoogleFonts.inter(
                              color: categoryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Quote Card ──────────────────────────────────────────
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _cardSlideAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Main quote card
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151525),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: categoryColor.withOpacity(0.22),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: categoryColor.withOpacity(0.14),
                                        blurRadius: 50,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 30,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Colored top strip
                                      Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(28),
                                          ),
                                          gradient: LinearGradient(
                                            colors: [
                                              categoryColor,
                                              categoryColor.withOpacity(0.4),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            28, 26, 28, 26),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Category badge
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: categoryColor
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: categoryColor
                                                          .withOpacity(0.4),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _currentQuote.category
                                                        .toUpperCase(),
                                                    style: GoogleFonts.inter(
                                                      color: categoryColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Favourite button
                                                _ActionIconButton(
                                                  icon: _isFavorited
                                                      ? Icons.favorite_rounded
                                                      : Icons
                                                          .favorite_border_rounded,
                                                  color: _isFavorited
                                                      ? const Color(0xFFFF6B6B)
                                                      : Colors.white38,
                                                  bgColor: _isFavorited
                                                      ? const Color(0xFFFF6B6B)
                                                          .withOpacity(0.18)
                                                      : Colors.white
                                                          .withOpacity(0.05),
                                                  onTap: () {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    setState(() =>
                                                        _isFavorited =
                                                            !_isFavorited);
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            // Large quote mark
                                            Text(
                                              '\u201C',
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                color: categoryColor
                                                    .withOpacity(0.5),
                                                fontSize: 80,
                                                height: 0.55,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 18),

                                            // Quote text
                                            Text(
                                              _currentQuote.text,
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                color: Colors.white
                                                    .withOpacity(0.95),
                                                fontSize: 21,
                                                fontWeight: FontWeight.w500,
                                                height: 1.7,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            // Divider
                                            Container(
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    categoryColor
                                                        .withOpacity(0.5),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            // Author row
                                            Row(
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        categoryColor,
                                                        categoryColor
                                                            .withOpacity(0.55),
                                                      ],
                                                      begin:
                                                          Alignment.topLeft,
                                                      end: Alignment
                                                          .bottomRight,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      _currentQuote.author[0],
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _currentQuote.author,
                                                        style: GoogleFonts.inter(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.9),
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Author & Thinker',
                                                        style: GoogleFonts.inter(
                                                          color:
                                                              Colors.white38,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Copy button
                                                _ActionIconButton(
                                                  icon: _isCopied
                                                      ? Icons.check_rounded
                                                      : Icons.copy_rounded,
                                                  color: _isCopied
                                                      ? categoryColor
                                                      : Colors.white38,
                                                  bgColor: _isCopied
                                                      ? categoryColor
                                                          .withOpacity(0.18)
                                                      : Colors.white
                                                          .withOpacity(0.05),
                                                  onTap: _onCopy,
                                                ),
                                                const SizedBox(width: 8),
                                                // Share button
                                                _ActionIconButton(
                                                  icon: _isShared
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons
                                                          .ios_share_rounded,
                                                  color: _isShared
                                                      ? categoryColor
                                                      : Colors.white38,
                                                  bgColor: _isShared
                                                      ? categoryColor
                                                          .withOpacity(0.18)
                                                      : Colors.white
                                                          .withOpacity(0.05),
                                                  onTap: _onShare,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // New Quote button
                                ScaleTransition(
                                  scale: _buttonScaleAnimation,
                                  child: GestureDetector(
                                    onTap: _onNewQuote,
                                    child: Container(
                                      width: double.infinity,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            categoryColor,
                                            categoryColor.withOpacity(0.7),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: categoryColor
                                                .withOpacity(0.45),
                                            blurRadius: 28,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'New Quote',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Swipe hint
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.swipe_rounded,
                                      color: Colors.white.withOpacity(0.18),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Swipe or tap for a new quote',
                                      style: GoogleFonts.inter(
                                        color: Colors.white24,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
      ),
    );
  }
}

// ── Reusable action icon button ──────────────────────────────────────────────
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
