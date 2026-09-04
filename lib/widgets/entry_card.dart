import 'dart:io';

import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';
import 'bean_icon.dart';

/// A feed post, Instagram-style: header, then a full-width photo (when there
/// is one) rather than a small side thumbnail, then rating/price and caption
/// below it — this is the primary way a user "shows off" their cupboard.
///
/// Tapping the card opens a read-only view ([onTap]); editing/deleting only
/// happens through the triple-dot menu ([onEdit]/[onDelete]), so a stray tap
/// while scrolling never accidentally lands you in an edit form.
class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EntryCard({super.key, required this.entry, this.onTap, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (entry.kind == EntryKind.skip) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: c.line, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '${fmtShortDate(entry.date)} — no coffee today, streak kept.',
          style: TextStyle(fontSize: 12.5, color: c.inkSoft),
        ),
      );
    }

    final isHome = entry.kind == EntryKind.home;
    final tagColor = isHome ? c.sageInk : c.clayInk;
    final tagBg = (isHome ? c.sage : c.clay).withValues(alpha: 0.18);
    final tagText = isHome
        ? 'Home'
        : (entry.venueTag != null ? entry.venueTag!.label : 'Away');
    final title = isHome ? (entry.method ?? 'Home brew') : (entry.venueName ?? 'Away');
    final subtitle = isHome ? 'Home brew' : (entry.method ?? '');
    final priceText = entry.free ? 'Free' : (entry.price != null ? peso(entry.price!) : '—');
    final hasPhoto = entry.photoPath != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 4, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tagBg,
                      shape: BoxShape.circle,
                    ),
                    child: BeanIcon(size: 18, color: tagColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          '$subtitle · ${fmtShortDate(entry.date)}',
                          style: TextStyle(fontSize: 12, color: c.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tagText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: tagColor,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                  if (entry.isSample) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SAMPLE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: c.inkFaint,
                        ),
                      ),
                    ),
                  ],
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<VoidCallback>(
                      icon: Icon(Icons.more_horiz, color: c.inkFaint, size: 20),
                      padding: EdgeInsets.zero,
                      onSelected: (action) => action(),
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(value: onEdit, child: const Text('Edit')),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: onDelete,
                            child: Text('Delete', style: TextStyle(color: c.danger)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (hasPhoto)
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Image.file(
                  File(entry.photoPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: c.surface2),
                ),
              )
            else
              _NoPhotoHero(entry: entry, tintColor: isHome ? c.sage : c.clay, iconColor: tagColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BeanRatingDisplay(rating: entry.rating, color: c.amber),
                      const SizedBox(width: 12),
                      Text(priceText, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if ((entry.caption ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$title  ',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          TextSpan(
                            text: entry.caption,
                            style: TextStyle(fontSize: 14, color: c.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if ((entry.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      entry.notes!,
                      style: TextStyle(fontSize: 13.5, color: c.inkSoft, height: 1.4),
                    ),
                  ],
                  if (entry.flavors.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.flavors
                          .map((f) => Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.surface2,
                                  border: Border.all(color: c.line),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(fontSize: 11.5, color: c.inkSoft),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stands in for a photo when the user didn't add one — a tinted banner
/// (Home/Away colored, like the header badge) instead of dead empty space,
/// so a photo-less cup still carries some visual weight in the feed.
class _NoPhotoHero extends StatelessWidget {
  final Entry entry;
  final Color tintColor;
  final Color iconColor;

  const _NoPhotoHero({required this.entry, required this.tintColor, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AspectRatio(
      aspectRatio: 2.6,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tintColor.withValues(alpha: 0.22),
              tintColor.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BeanIcon(size: 36, color: iconColor),
                if ((entry.method ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.method!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          color: c.ink,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
