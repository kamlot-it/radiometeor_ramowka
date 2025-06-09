import 'package:flutter/material.dart';
import '../../data/models/program.dart';
import '../../config/theme_config.dart';

class ProgramCard extends StatelessWidget {
  final Program program;
  final bool isCurrentlyPlaying;

  const ProgramCard({
    super.key,
    required this.program,
    this.isCurrentlyPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isCurrentlyPlaying ? 4 : 2,
        color: isCurrentlyPlaying
            ? ThemeConfig.primaryOrange.withOpacity(0.1)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentlyPlaying
              ? const BorderSide(color: ThemeConfig.primaryOrange, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showProgramDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTimeSection(),
                const SizedBox(width: 16),
                _buildCategoryIndicator(),
                const SizedBox(width: 12),
                Expanded(child: _buildContentSection()),
                if (isCurrentlyPlaying) _buildLiveIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentlyPlaying
            ? ThemeConfig.primaryOrange
            : ThemeConfig.darkGrey.withOpacity(0.8), // Ciemniejsze tło dla kontrastu
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            program.startTime,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Zawsze biały dla czytelności
            ),
          ),
          Container(
            width: 20,
            height: 1,
            color: Colors.white.withOpacity(0.7), // Biała linia rozdzielająca
            margin: const EdgeInsets.symmetric(vertical: 2),
          ),
          Text(
            program.endTime,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9), // Lekko przezroczysty biały
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIndicator() {
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: program.categoryColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                program.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrentlyPlaying
                      ? ThemeConfig.primaryOrange
                      : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildCategoryBadge(),
          ],
        ),
        const SizedBox(height: 4),
        if (program.hosts?.isNotEmpty == true) ...[
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: ThemeConfig.mediumGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  program.hosts!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ThemeConfig.mediumGrey,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: ThemeConfig.mediumGrey,
            ),
            const SizedBox(width: 4),
            Text(
              'Czas trwania: ${program.duration}',
              style: const TextStyle(
                fontSize: 12,
                color: ThemeConfig.mediumGrey,
              ),
            ),
          ],
        ),
        if (program.description != null && program.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            program.description!,
            style: const TextStyle(
              fontSize: 13,
              color: ThemeConfig.mediumGrey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: program.categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: program.categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        program.categoryName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: program.categoryColor,
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ThemeConfig.errorRed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'NA ŻYWO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProgramDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          program.title,
          style: const TextStyle(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Czas', program.timeRange),
            _buildDetailRow('Czas trwania', program.duration),
            if (program.hosts?.isNotEmpty == true)
              _buildDetailRow('Prowadzący', program.hosts!),
            if (program.description != null && program.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Opis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(program.description!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ThemeConfig.mediumGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
