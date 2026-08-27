import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class GuideBundleSheet extends StatelessWidget {
  final LocalGuideModel guide;
  final bool isBundled;
  final VoidCallback onToggleBundle;

  const GuideBundleSheet({
    super.key,
    required this.guide,
    required this.isBundled,
    required this.onToggleBundle,
  });

  static void show(
    BuildContext context, {
    required LocalGuideModel guide,
    required bool isBundled,
    required VoidCallback onToggleBundle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuideBundleSheet(
        guide: guide,
        isBundled: isBundled,
        onToggleBundle: onToggleBundle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable Profile Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guide Header (Avatar, Name, Badge, Rating)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: CachedNetworkImage(
                          imageUrl: guide.profilePhotoUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const CircleAvatar(radius: 36, backgroundColor: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  guide.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (guide.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              guide.headline,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  guide.rating.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  " (${guide.reviewCount} reviews)",
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Highlights Bar (Experience, Languages, Daily Rate)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol("EXPERIENCE", "${guide.yearsOfExperience} Years", Icons.workspace_premium),
                        Container(width: 1, height: 30, color: AppTheme.divider),
                        _buildStatCol("DAILY FEE", "\$${guide.dailyRate.toStringAsFixed(0)}", Icons.monetization_on),
                        Container(width: 1, height: 30, color: AppTheme.divider),
                        _buildStatCol("LANGUAGES", "${guide.languages.length} Spoken", Icons.language),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Languages Tags
                  const Text(
                    "Spoken Languages",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: guide.languages.map((lang) {
                      return Chip(
                        label: Text(lang, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        backgroundColor: AppTheme.surface,
                        side: const BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Tour Specialties
                  const Text(
                    "Curated Tour Specialties",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: guide.specialties.map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.guideLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.guideGold.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.explore, size: 14, color: AppTheme.guideGold),
                            const SizedBox(width: 5),
                            Text(
                              spec,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.guideGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Biography
                  const Text(
                    "About the Guide",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.bio ?? "Certified local tour guide offering exclusive experiences.",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Action Bar (Toggle Bundle)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppTheme.divider)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("GUIDE BUNDLE FEE", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    Text(
                      "\$${guide.dailyRate.toStringAsFixed(0)} / day",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.guideGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBundled ? Colors.red.shade600 : AppTheme.guideGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      onToggleBundle();
                      Navigator.pop(context);
                    },
                    icon: Icon(isBundled ? Icons.remove_circle_outline : Icons.add_circle_outline),
                    label: Text(
                      isBundled ? "Remove Guide Bundle" : "Bundle Guide with Resort",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

  Widget _buildStatCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.resortAccent),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
