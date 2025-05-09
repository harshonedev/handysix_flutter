import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/core/utils/string_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final groundHeight = screenHeight * 0.3;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppBar(),

            const SizedBox(height: 24),

            // Wrap Stack in a SizedBox with a defined height
            SizedBox(
              height: groundHeight,
              child: Stack(
                // Remove StackFit.expand since we now have a defined container size
                alignment: Alignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/images/cricket_ground.svg',
                      fit: BoxFit.cover,
                      height: groundHeight,
                      colorFilter: ColorFilter.mode(
                        AppTheme.backgroundColor.withOpacity(0.8),
                        BlendMode.srcATop,
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/hand_gestures/3_left.png',
                        width: MediaQuery.of(context).size.width * 0.45,
                      ),

                      Image.asset(
                        'assets/hand_gestures/2_right.png',
                        width: MediaQuery.of(context).size.width * 0.45,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildModes(),
          ],
        ),
      ),
    );
  }

  Widget _buildModes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Play Modes',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Replace Row with GridView
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.count(
            // Disable scrolling in GridView since it's inside a Column
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            // Define grid properties
            crossAxisCount: 2, // Number of columns
            crossAxisSpacing: 6, // Horizontal space between items
            mainAxisSpacing: 8, // Vertical space between items
            childAspectRatio: 0.8, // Width-to-height ratio
            children: [
              _buildModeCard(
                'assets/images/helmet.svg',
                'Online Match',
                'Play with real players online',
                Color(0xFFFAFAFA),
                () {
                  // Handle Online Match button press
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Online Match button pressed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildModeCard(
                'assets/images/target.svg',
                'Practice Match',
                'Play with AI bot',
                Color(0xFFEE746C),
                () {
                  // Handle Practice Match button press
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Practice Match button pressed'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // You can easily add more cards here in the future
            ],
          ),
        ),
      ],
    );
  }

  // Update your card to work with GridView
  Widget _buildModeCard(
    String imagePath,
    String title,
    String description,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: onPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),

              const Spacer(),

              Align(
                alignment: Alignment.bottomRight,
                child: SvgPicture.asset(
                  imagePath,
                  height: 80,
                  width: 80,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.2),
                    BlendMode.srcATop,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: InkWell(
              onTap: () {
                // Handle avatar tap
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Avatar tapped'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Image.network(
                AppConstants.avatarUrl,
                errorBuilder:
                    (context, error, stackTrace) =>
                        Image.asset('assets/images/batman_avatar.png'),

                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),

          SizedBox(width: 8),

          Text(
            StringUtils.limitTextLength('Guest', maxLength: 8),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: InkWell(
                onTap: () {
                  // Handle score tap
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Score tapped'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      StringUtils.limitTextLength('2034', maxLength: 5),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(width: 8),
                    SvgPicture.asset(
                      'assets/images/cricket_ball.svg',
                      height: 20,
                      width: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
