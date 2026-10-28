import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather.dart';

class Candidate {
  Candidate(this.name, [this.votes = 0]);
  String name;
  int votes;

  Map<String, dynamic> toJson() => {'name': name, 'votes': votes};
  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(json['name'] as String, json['votes'] as int);
  }
}

void main() {
  runApp(const ElectionApp());
}

String cleanName(String raw) {
  final words = raw.trim().split(RegExp(r'\s+'));
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

class ElectionApp extends StatelessWidget {
  const ElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Class Election',
      theme: ThemeData(
        colorScheme: base,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        appBarTheme: AppBarTheme(
          backgroundColor: base.primary,
          foregroundColor: base.onPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const VoteScreen(),
    );
  }
}

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final candidates = <Candidate>[];
  final voters = <String>{};
  final voterController = TextEditingController();

  // API State
  WeatherData? weather;
  bool loadingWeather = true;
  bool weatherError = false;

  @override
  void initState() {
    super.initState();
    loadData();
    loadWeather();
  }

  @override
  void dispose() {
    voterController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('candidates');
    final savedVoters = prefs.getStringList('voters');

    setState(() {
      if (saved != null) {
        final list = jsonDecode(saved) as List;
        candidates.clear();
        candidates.addAll(list.map((x) => Candidate.fromJson(x)).toList());
      } else {
        candidates.addAll([Candidate('Keza'), Candidate('Mutoni'), Candidate('Gisa')]);
      }

      if (savedVoters != null) {
        voters.clear();
        voters.addAll(savedVoters);
      }
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final list = candidates.map((c) => c.toJson()).toList();
    await prefs.setString('candidates', jsonEncode(list));
    await prefs.setStringList('voters', voters.toList());
  }

  Future<void> loadWeather() async {
    setState(() {
      loadingWeather = true;
      weatherError = false;
    });
    try {
      final w = await fetchWeather();
      setState(() {
        weather = w;
        loadingWeather = false;
      });
    } catch (e) {
      setState(() {
        weatherError = true;
        loadingWeather = false;
      });
    }
  }

  void vote(Candidate c) {
    final cleaned = cleanName(voterController.text);

    if (cleaned.isEmpty) {
      _toast('Type your name first', Colors.red.shade600);
      return;
    }

    final key = cleaned.toLowerCase();
    if (voters.contains(key)) {
      _toast('$cleaned has already voted', Colors.orange.shade700);
      return;
    }

    setState(() {
      c.votes += 1;
      voters.add(key);
    });
    saveData();

    _toast('$cleaned voted for ${c.name}', Colors.green.shade600);
    voterController.clear();
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void openCandidates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidatesScreen(candidates: candidates),
      ),
    ).then((_) {
      setState(() {});
      saveData();
    });
  }

  void openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(candidates: candidates, onReset: saveData),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = candidates.fold<int>(0, (s, c) => s + c.votes);
    final votersCount = voters.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Election'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Candidates',
            onPressed: openCandidates,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Results',
            onPressed: openResults,
          ),
        ],
      ),
      body: Column(
        children: [
          // API & Stats Container
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: loadingWeather
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : weatherError
                ? Column(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(height: 4),
                const Text('Could not load live weather', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: loadWeather,
                  child: const Text('Retry', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
                ),
              ],
            )
                : Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live API', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('Kigali: ${weather!.temperature.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(child: _stat('Voters', '$votersCount')),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(child: _stat('Total votes', '$totalVotes')),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _stat('Candidates', '${candidates.length}'),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: voterController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Your name',
                hintText: 'e.g. Aline Uwase',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: candidates.isEmpty
                ? const Center(
              child: Text(
                'No candidates yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final c = candidates[index];
                return _CandidateCard(
                  candidate: c,
                  total: totalVotes,
                  onVote: () => vote(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.total,
    required this.onVote,
  });

  final Candidate candidate;
  final int total;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : candidate.votes / total;
    final color = _colorFor(candidate.name);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              candidate.name.isNotEmpty ? candidate.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${candidate.votes} vote${candidate.votes == 1 ? '' : 's'} · ${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onVote,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Vote'),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String name) {
    const palette = [
      Color(0xFF4F46E5),
      Color(0xFF059669),
      Color(0xFFEA580C),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFFDB2777),
    ];
    final hash = name.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    return palette[hash % palette.length];
  }
}

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key, required this.candidates});
  final List<Candidate> candidates;

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void addCandidate() {
    final cleaned = cleanName(nameController.text);
    if (cleaned.isEmpty) {
      _toast('Candidate name cannot be empty', Colors.red.shade600);
      return;
    }

    final exists = widget.candidates.any(
          (c) => c.name.toLowerCase() == cleaned.toLowerCase(),
    );
    if (exists) {
      _toast('$cleaned is already a candidate', Colors.orange.shade700);
      return;
    }

    setState(() {
      widget.candidates.add(Candidate(cleaned));
    });
    nameController.clear();
    _toast('Added $cleaned', Colors.green.shade600);
  }

  void removeCandidate(Candidate c) {
    if (c.votes > 0) {
      _toast(
        '${c.name} has votes and cannot be removed',
        Colors.orange.shade700,
      );
      return;
    }
    setState(() {
      widget.candidates.remove(c);
    });
    _toast('Removed ${c.name}', Colors.grey.shade700);
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'New candidate',
                      prefixIcon: const Icon(Icons.person_add_alt),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => addCandidate(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: addCandidate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.candidates.isEmpty
                ? const Center(
              child: Text(
                'No candidates yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: widget.candidates.length,
              itemBuilder: (context, index) {
                final c = widget.candidates[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                      Theme.of(context).colorScheme.primary,
                      child: Text(
                        c.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style:
                      const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${c.votes} vote(s)'),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: c.votes > 0
                            ? Colors.grey.shade400
                            : Colors.red.shade400,
                      ),
                      onPressed: () => removeCandidate(c),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.candidates, required this.onReset});
  final List<Candidate> candidates;
  final VoidCallback onReset;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  void resetVotes() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reset all votes?'),
        content: const Text('This clears every vote and every voter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                for (var c in widget.candidates) {
                  c.votes = 0;
                }
              });
              widget.onReset();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.candidates.fold<int>(0, (sum, c) => sum + c.votes);
    final sorted = [...widget.candidates]
      ..sort((a, b) => b.votes.compareTo(a.votes));

    Widget banner;
    if (total == 0) {
      banner = const _Banner(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        icon: Icons.hourglass_empty,
        title: 'No votes yet',
        subtitle: 'Cast a vote to see results',
      );
    } else {
      final top = sorted.first.votes;
      final winners = sorted.where((c) => c.votes == top).toList();
      if (winners.length > 1) {
        final names = winners.map((c) => c.name).join(' and ');
        banner = _Banner(
          colors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
          icon: Icons.balance,
          title: 'Tie',
          subtitle: '$names · $top votes each',
        );
      } else {
        banner = _Banner(
          colors: const [Color(0xFF10B981), Color(0xFF059669)],
          icon: Icons.emoji_events,
          title: 'Winner: ${winners.first.name}',
          subtitle: '$top vote${top == 1 ? '' : 's'}',
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset all votes',
            onPressed: total == 0 ? null : resetVotes,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            banner,
            const SizedBox(height: 16),
            Expanded(
              child: sorted.isEmpty
                  ? const Center(
                child: Text(
                  'No candidates yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final c = sorted[index];
                  final pct = total == 0 ? 0.0 : c.votes / total;
                  final position = index + 1;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: _medalColor(position),
                              child: Text(
                                '$position',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${c.votes} (${(pct * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              _medalColor(position),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _medalColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFF94A3B8);
      case 3:
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<Color> colors;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}