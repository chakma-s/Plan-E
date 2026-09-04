import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'hotel_search_screen.dart';
import 'resort_search_screen.dart';
import 'my_trips_screen.dart';import '../widgets/auth_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flight_takeoff, color: AppTheme.blackColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "Plan-E",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(state.currentTheme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: AppTheme.brandColor),
            onPressed: () {
              state.toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              state.isAuthenticated ? Icons.account_circle : Icons.account_circle_outlined,
              color: state.isAuthenticated ? AppTheme.brandColor : AppTheme.getTextColor(context),
            ),
            onPressed: () {
              if (!state.isAuthenticated) {
                AuthBottomSheet.show(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Already logged in")));
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
            ),
            child: _buildDualJourneySegmentedControl(state),
          ),
        ),
      ),
      body: IndexedStack(
        index: currentNavIndex,
        children: [
          // Explore Tab (switches between Hotel and Resort screens based on state)
          state.activeJourney == JourneyType.hotel
              ? const HotelSearchScreen()
              : const ResortSearchScreen(),
          const MyTripsScreen(),
          const Center(child: Text("Traveler Profile & Settings")),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentNavIndex,
        selectedItemColor: state.activeJourney == JourneyType.hotel
            ? AppTheme.hotelAccent
            : AppTheme.resortAccent,
        unselectedItemColor: AppTheme.textMuted,
        onTap: (index) {
          setState(() {
            currentNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: "My Trips"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildDualJourneySegmentedControl(AppState state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getDividerColor(context)),
      ),
      child: Row(
        children: [
          // 1. Hotel Journey Tab (Fast, Transactional)
          Expanded(
            child: GestureDetector(
              onTap: () => state.setJourney(JourneyType.hotel),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: state.activeJourney == JourneyType.hotel
                      ? AppTheme.hotelAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: state.activeJourney == JourneyType.hotel
                      ? [BoxShadow(color: AppTheme.hotelAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 16,
                      color: state.activeJourney == JourneyType.hotel ? AppTheme.blackColor : AppTheme.getSecondaryTextColor(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "HOTELS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: state.activeJourney == JourneyType.hotel ? AppTheme.blackColor : AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 2. Resort Journey Tab (Immersive Vacation + Guides)
          Expanded(
            child: GestureDetector(
              onTap: () => state.setJourney(JourneyType.resort),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: state.activeJourney == JourneyType.resort
                      ? AppTheme.resortAccent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: state.activeJourney == JourneyType.resort
                      ? [BoxShadow(color: AppTheme.resortAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.beach_access,
                      size: 16,
                      color: state.activeJourney == JourneyType.resort ? AppTheme.blackColor : AppTheme.getSecondaryTextColor(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "RESORTS",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: state.activeJourney == JourneyType.resort ? AppTheme.blackColor : AppTheme.getSecondaryTextColor(context),
                      ),
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
