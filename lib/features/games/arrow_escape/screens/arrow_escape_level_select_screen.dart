import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'arrow_escape_game_screen.dart';

class NativeArrowEscapeLevelSelectScreen extends StatelessWidget {
  const NativeArrowEscapeLevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SELECT LEVEL',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        itemCount: 200,
        itemBuilder: (context, index) {
          final levelNum = index + 1;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NativeArrowEscapeGameScreen(
                    initialLevel: levelNum,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: levelNum == 1 ? const Color(0xFF1E261B) : const Color(0xFF161920),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: levelNum == 1 ? const Color(0xFF76ED12) : const Color(0xFF282C36),
                  width: levelNum == 1 ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$levelNum',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      color: levelNum == 1 ? const Color(0xFF76ED12) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (starIdx) {
                      return Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: starIdx == 0 ? const Color(0xFFFFEA00) : Colors.white24,
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
