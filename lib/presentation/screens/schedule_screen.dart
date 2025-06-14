import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../widgets/program_card.dart';
import '../widgets/week_selector.dart';
import '../widgets/day_selector.dart';
import '../../config/theme_config.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late ScrollController _scrollController; // 🔥 DODANY SCROLL CONTROLLER

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scrollController = ScrollController(); // 🔥 INICJALIZACJA
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose(); // 🔥 CZYSZCZENIE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
      drawer: _buildDrawer(),
    );
  }

  // 🔥 NOWA METODA AUTO-SCROLL DO LIVE PROGRAMU
  void _scrollToLiveProgram(ScheduleProvider provider) {
    final programs = provider.programsForSelectedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      // Znajdź indeks aktualnie granego programu
      final liveIndex = programs.indexWhere(
        (program) => provider.isProgramCurrentlyPlaying(program),
      );

      if (liveIndex != -1) {
        debugPrint('🎯 Przewijam do Live programu na pozycji: $liveIndex');

        // Wysokość jednej karty programu (szacunkowo)
        const itemHeight = 120.0;
        const headerHeight = 260.0; // Wysokość sklejonych nagłówków

        // Oblicz pozycję scroll - wyśrodkuj live program
        final screenHeight = MediaQuery.of(context).size.height;
        final targetPosition =
            (liveIndex * itemHeight) + headerHeight - (screenHeight / 3);

        // Animowane przewijanie do live programu
        _scrollController.animateTo(
          targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        debugPrint('🔍 Brak aktualnie granego programu - przewijam na górę');
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ramówka – ${provider.selectedWeek}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (provider.lastUpdated != null)
                Text(
                  'Aktualizacja: ${_formatLastUpdate(provider.lastUpdated!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        Consumer<ScheduleProvider>(
          builder: (context, provider, child) {
            return WeekSelector(
              selectedWeek: provider.selectedWeek,
              onWeekChanged: (week) => provider.changeWeek(week),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        switch (provider.state) {
          case ScheduleState.initial:
          case ScheduleState.loading:
            return _buildLoadingState();

          case ScheduleState.error:
            return _buildErrorState(provider);

          case ScheduleState.loaded:
          case ScheduleState.refreshing:
            // 🔥 AUTO-SCROLL PO ZAŁADOWANIU DANYCH
            if (provider.programsForSelectedDay.isNotEmpty) {
              _scrollToLiveProgram(provider);
            }
            return _buildLoadedState(provider);

          default:
            return _buildLoadingState();
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ThemeConfig.primaryOrange,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Ładowanie ramówki...',
            style: TextStyle(fontSize: 16, color: ThemeConfig.mediumGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsList(ScheduleProvider provider) {
  }

  Widget _buildErrorState(ScheduleProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThemeConfig.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: ThemeConfig.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Błąd ładowania ramówki',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Nieznany błąd',
              style: const TextStyle(
                fontSize: 14,
                color: ThemeConfig.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => provider.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Spróbuj ponownie'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showTroubleshootingDialog(),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Pomoc'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(ScheduleProvider provider) {
    if (provider.programs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: ThemeConfig.primaryOrange,
      child: CustomScrollView(
        controller: _scrollController, // 🔥 PODŁĄCZONY SCROLL CONTROLLER
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: _buildStatsHeader(provider),
              height: 100,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: _buildCurrentProgramHeader(provider),
              height: provider.currentProgram != null ? 110 : 0,
            ),
          ),
          _buildProgramsList(provider),
          // 🔥 DODATKOWY PADDING NA DOLE
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.radio,
                size: 64,
                color: ThemeConfig.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Brak programów w ramówce',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sprawdź konfigurację Google Sheets lub spróbuj później',
              style: TextStyle(fontSize: 14, color: ThemeConfig.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(ScheduleProvider provider) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeConfig.primaryOrange,
              ThemeConfig.primaryOrange.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.primaryOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DaySelector(
          selectedDay: provider.selectedDay,
          currentDay: provider.todayName,
          onDayChanged: provider.changeDay,
        ),
      ),
    );
  }

  Widget _buildCurrentProgramHeader(ScheduleProvider provider) {
    final currentProgram = provider.currentProgram;

    if (currentProgram == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Card(
          color: ThemeConfig.successGreen,
          elevation: 8, // 🔥 PODWYŻSZONA ELEVACJA DLA LIVE PROGRAMU
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.radio, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'TERAZ NA ANTENIE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 🔥 ANIMOWANA KROPKA LIVE
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentProgram.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentProgram.hosts?.isNotEmpty == true)
                      Text(
                        currentProgram.hosts!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                currentProgram.timeRange,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    );
  }

  Widget _buildProgramsList(ScheduleProvider provider) {
    final programs = provider.programsForSelectedDay;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final program = programs[index];
          return ProgramCard(
            program: program,
            isCurrentlyPlaying: provider.isProgramCurrentlyPlaying(program),
          );
        }, childCount: programs.length),
      ),
    );
  }

  Widget _buildFAB() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        if (provider.state == ScheduleState.refreshing) {
          return FloatingActionButton(
            onPressed: null,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        return FloatingActionButton(
          onPressed: () {
            _refreshController.forward().then(
              (_) => _refreshController.reset(),
            );
            provider.refresh();
          },
          tooltip: 'Odśwież ramówkę',
          child: AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshController.value * 2 * 3.14159,
                child: const Icon(Icons.refresh),
              );
            },
          ),
        );
      },
    );
  }

  // Reszta metod pozostaje bez zmian...
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: ThemeConfig.primaryOrange),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.radio, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'Ramówka Radiowa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Profesjonalna aplikacja ramówki',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('O aplikacji'),
            onTap: () {
              Navigator.pop(context);
              _showInfoDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Pomoc'),
            onTap: () {
              Navigator.pop(context);
              _showTroubleshootingDialog();
            },
          ),
          const Divider(),
          Consumer<ScheduleProvider>(
            builder: (context, provider, child) {
              return ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: const Text('Test połączenia'),
                onTap: () async {
                  Navigator.pop(context);
                  await _testConnection(provider);
                },
              );
            },
          ),
          Consumer<ScheduleProvider>(
            builder: (context, provider, child) {
              return ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Wyczyść cache'),
                onTap: () {
                  Navigator.pop(context);
                  _clearCache(provider);
                },
              );
            },
          ),
          // 🔥 NOWA OPCJA - PRZEJDŹ DO LIVE PROGRAMU
          Consumer<ScheduleProvider>(
            builder: (context, provider, child) {
              final hasLiveProgram = provider.currentProgram != null;
              return ListTile(
                leading: Icon(
                  Icons.radio,
                  color: hasLiveProgram
                      ? ThemeConfig.successGreen
                      : ThemeConfig.mediumGrey,
                ),
                title: Text(
                  hasLiveProgram ? 'Przejdź do Live' : 'Brak Live programu',
                  style: TextStyle(
                    color: hasLiveProgram ? null : ThemeConfig.mediumGrey,
                  ),
                ),
                onTap: hasLiveProgram
                    ? () {
                        Navigator.pop(context);
                        _scrollToLiveProgram(provider);
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'właśnie';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min temu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} godz. temu';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O aplikacji'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ramówka Radiowa v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Profesjonalna aplikacja do zarządzania ramówką radiową z integracją Google Sheets.',
            ),
            SizedBox(height: 16),
            Text('Funkcje:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Integracja z Google Sheets'),
            Text('• Auto-scroll do Live programu'),
            Text('• Przełączanie między tygodniami A/B'),
            Text('• Responsive design'),
            Text('• Offline support'),
            Text('• Polskie tłumaczenie'),
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

  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomoc'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Najczęstsze problemy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Brak połączenia z internetem'),
              Text('   → Sprawdź połączenie WiFi/dane mobilne'),
              SizedBox(height: 8),
              Text('2. Błąd Google Sheets API'),
              Text('   → Sprawdź konfigurację API key'),
              Text('   → Upewnij się, że arkusz jest publiczny'),
              SizedBox(height: 8),
              Text('3. Auto-scroll nie działa'),
              Text('   → Sprawdź czy jest aktualnie grany program'),
              Text('   → Odśwież ramówkę'),
            ],
          ),
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

  Future<void> _testConnection(ScheduleProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testowanie połączenia...'),
          ],
        ),
      ),
    );

    final isConnected = await provider.testConnection();

    if (mounted) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isConnected ? 'Połączenie OK' : 'Błąd połączenia'),
          content: Text(
            isConnected
                ? 'Połączenie z Google Sheets działa prawidłowo.'
                : 'Nie można połączyć się z Google Sheets. Sprawdź konfigurację.',
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
  }

  void _clearCache(ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyść cache'),
        content: const Text(
          'Czy na pewno chcesz wyczyścić zapisane dane? Aplikacja pobierze je ponownie z Google Sheets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.clearCache();
              provider.refresh();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache wyczyszczony'),
                  backgroundColor: ThemeConfig.successGreen,
                ),
              );
            },
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

void debugPrint(String message) {
  print('[ScheduleScreen] $message');
}
