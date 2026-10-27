import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/history/history_db.dart';
import 'package:jasstafel/common/history/history_statistics.dart';
import 'package:jasstafel/common/localization.dart';

/// The settings tile that opens the history of a board.
class HistoryButton extends StatelessWidget {
  const HistoryButton(this.board, {super.key, this.db});

  final Board board;
  final HistoryDb? db;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('history'),
      title: Text(context.l10n.history),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (context) => HistoryPage(board, db: db)),
      ),
    );
  }
}

/// The games of a board that ended: how everyone did over all of them, and
/// the games one by one, the latest first.
class HistoryPage extends StatefulWidget {
  HistoryPage(this.board, {super.key, HistoryDb? db})
    : db = db ?? HistoryDb.instance;

  final Board board;
  final HistoryDb db;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<GameRecord>> _games = widget.db.games(widget.board);

  void _reload() {
    if (!mounted) return;
    setState(() {
      _games = widget.db.games(widget.board);
    });
  }

  String _date(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(time);
  }

  Future<void> _deleteAll() async {
    await confirmDialog(
      context: context,
      title: context.l10n.deleteHistory,
      subtitle: context.l10n.deleteHistoryConfirm,
      actions: [
        DialogAction(
          text: context.l10n.ok,
          action: () async {
            await widget.db.deleteAll(widget.board);
            _reload();
          },
        ),
      ],
    );
  }

  Future<void> _delete(GameRecord game) async {
    await confirmDialog(
      context: context,
      title: context.l10n.deleteGame,
      subtitle: context.l10n.deleteGameConfirm(_date(context, game.ended)),
      actions: [
        DialogAction(
          text: context.l10n.ok,
          action: () async {
            await widget.db.delete(game.id);
            _reload();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.history),
        actions: [
          IconButton(
            key: const Key('deleteHistory'),
            tooltip: context.l10n.deleteHistory,
            icon: const Icon(Icons.delete_sweep),
            onPressed: _deleteAll,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _games,
        builder: (context, snapshot) {
          final games = snapshot.data;
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          if (games == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (games.isEmpty) {
            return Center(child: Text(context.l10n.historyEmpty));
          }
          return ListView(
            children: [
              ...switch (HistoryStatistics(games)) {
                final stats when stats.finished > 0 => [
                  _Summary(stats),
                  if (stats.hasTeams) _PlayerSummary(stats),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
                _ => const <Widget>[],
              },
              for (final game in games)
                _GameTile(
                  game,
                  date: _date(context, game.ended),
                  onDelete: () => _delete(game),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Games, wins and average points of every team or player.
class _Summary extends StatelessWidget {
  const _Summary(this.stats);

  final HistoryStatistics stats;

  @override
  Widget build(BuildContext context) => _Table(
    header: [
      context.l10n.historyGames(stats.finished),
      context.l10n.games,
      context.l10n.wins,
      context.l10n.historyAverage,
      for (final kind in stats.detailKinds)
        context.l10n.historyAverageOf(_detailName(context, kind, short: true)),
    ],
    rows: [
      for (final name in stats.names)
        [
          name.name,
          '${name.games}',
          '${name.wins}',
          name.average.round().toString(),
          for (final kind in stats.detailKinds)
            name.averageOf(kind).round().toString(),
        ],
    ],
  );
}

/// Games, wins and win rate of every player of the teams.
class _PlayerSummary extends StatelessWidget {
  const _PlayerSummary(this.stats);

  final HistoryStatistics stats;

  @override
  Widget build(BuildContext context) => _Table(
    header: [
      context.l10n.historyPlayers,
      context.l10n.games,
      context.l10n.wins,
      context.l10n.historyWinRate,
    ],
    rows: [
      for (final player in stats.players)
        [
          player.name,
          '${player.games}',
          '${player.wins}',
          '${(player.winRate * 100).round()} %',
        ],
    ],
  );
}

/// A name column and numbers, under a bold header.
class _Table extends StatelessWidget {
  const _Table({required this.header, required this.rows});

  final List<String> header;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final bold = style?.copyWith(fontWeight: FontWeight.bold);

    // A narrow screen leaves the columns little room: the header wraps
    // between words and shrinks rather than cutting them.
    final headerGroup = AutoSizeGroup();
    Widget row(List<String> cells, TextStyle? style, {bool header = false}) =>
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < cells.length; i++)
              Expanded(
                flex: i == 0 ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: header
                      ? AutoSizeText(
                          cells[i],
                          style: style,
                          textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                          maxLines: 2,
                          wrapWords: false,
                          minFontSize: 8,
                          group: headerGroup,
                        )
                      : Text(
                          cells[i],
                          style: style,
                          textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          row(header, bold, header: true),
          for (final cells in rows) row(cells, style),
        ],
      ),
    );
  }
}

/// One game: who played and how it stood, the winners in bold.
class _GameTile extends StatelessWidget {
  const _GameTile(this.game, {required this.date, required this.onDelete});

  final GameRecord game;
  final String date;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final bold = style.copyWith(fontWeight: FontWeight.bold);
    final spans = <InlineSpan>[];
    for (var i = 0; i < game.names.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '  |  '));
      final won = game.winners.contains(game.names[i]);
      final total = i < game.totals.length ? ' ${game.totals[i]}' : '';
      spans.add(
        TextSpan(text: '${game.names[i]}$total', style: won ? bold : null),
      );
    }

    final subtitle = [
      date,
      if (game.started case final started?)
        if (Timestamps.playedMinutes(started, game.ended) case final minutes?)
          context.l10n.duration(minutes),
      for (final MapEntry(key: kind, value: values) in game.details.entries)
        if (values.any((v) => v != 0))
          '${_detailName(context, kind)} ${values.join(' | ')}',
      if (!game.finished) context.l10n.historyUnfinished,
    ].join('  ·  ');

    return ListTile(
      title: Text.rich(TextSpan(children: spans)),
      subtitle: Text(subtitle),
      trailing: IconButton(
        tooltip: context.l10n.deleteGame,
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}

/// The name of a detail kind, see `GameRecord.details`, [short] for a
/// column.
String _detailName(BuildContext context, String kind, {bool short = false}) =>
    switch (kind) {
      'weis' => context.l10n.weis,
      'handWeis' => short ? context.l10n.historyHand : context.l10n.handWeis,
      'tableWeis' => short ? context.l10n.historyTable : context.l10n.tableWeis,
      _ => kind,
    };
