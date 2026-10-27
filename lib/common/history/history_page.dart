import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/history/history_db.dart';
import 'package:jasstafel/common/history/history_statistics.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';

/// The history part of a board's settings. None on the web, which has no
/// database to keep the games in.
List<Widget> historySection(BuildContext context, Board board) => kIsWeb
    ? const []
    : [
        sectionTitle(context, context.l10n.history),
        HistoryButton(board),
        const Divider(),
      ];

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
    return FutureBuilder(
      future: _games,
      builder: (context, snapshot) {
        final games = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.history),
            actions: [
              if (games != null && games.isNotEmpty)
                IconButton(
                  key: const Key('deleteHistory'),
                  tooltip: context.l10n.deleteHistory,
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _deleteAll,
                ),
            ],
          ),
          body: _body(context, snapshot),
        );
      },
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<List<GameRecord>> snapshot) {
    final games = snapshot.data;
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.historyLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              // For a report of the error.
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
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
  }
}

/// Games, wins and average points of every team or player.
class _Summary extends StatelessWidget {
  const _Summary(this.stats);

  final HistoryStatistics stats;

  @override
  Widget build(BuildContext context) => _Table(
    header: [
      _Header(
        stats.finished == stats.games
            ? context.l10n.historyGames(stats.games)
            : context.l10n.historyFinishedOf(stats.finished, stats.games),
      ),
      _Header(context.l10n.games),
      _Header(context.l10n.wins),
      _Header(context.l10n.historyAverage),
      for (final kind in stats.detailKinds)
        switch (_detailIcon(kind)) {
          final asset? => _Header.icon(
            context.l10n.historyAverageOf(_Header.mark),
            asset,
            _detailName(context, kind),
          ),
          null => _Header(
            context.l10n.historyAverageOf(_detailName(context, kind)),
          ),
        },
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
      for (final text in [
        context.l10n.historyPlayers,
        context.l10n.games,
        context.l10n.wins,
        context.l10n.historyWinRate,
      ])
        _Header(text),
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

/// A cell of a table's header: its text, or an icon in place of [mark].
class _Header {
  const _Header(this.text) : icon = null;
  const _Header.icon(this.text, String asset, String label)
    : icon = (asset: asset, label: label);

  /// Where the icon goes in the text, such as "Ø" before it.
  // cspell:disable-next-line
  static const mark = '\u{FFFC}';

  final String text;
  final ({String asset, String label})? icon;
}

/// A name column and numbers, under a bold header.
class _Table extends StatelessWidget {
  const _Table({required this.header, required this.rows});

  final List<_Header> header;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final bold = style?.copyWith(fontWeight: FontWeight.bold);

    // A narrow screen leaves the columns little room: the header wraps
    // between words and shrinks rather than cutting them.
    final headerGroup = AutoSizeGroup();
    Widget headerCell(_Header cell, TextAlign align) {
      final icon = cell.icon;
      if (icon == null) {
        return AutoSizeText(
          cell.text,
          style: bold,
          textAlign: align,
          maxLines: 2,
          wrapWords: false,
          minFontSize: 8,
          group: headerGroup,
        );
      }
      final [before, after] = [
        for (final part in cell.text.split(_Header.mark)) part.trim(),
      ];
      // Shrinks on a narrow screen rather than overflowing its column.
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (before.isNotEmpty) Text(before, style: bold),
            SvgPicture.asset(
              icon.asset,
              height: 32,
              semanticsLabel: icon.label,
            ),
            if (after.isNotEmpty) Text(after, style: bold),
          ],
        ),
      );
    }

    TextAlign align(int column) =>
        column == 0 ? TextAlign.left : TextAlign.center;

    Widget row(List<Widget> cells) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: i == 0 ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: cells[i],
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          row([
            for (var i = 0; i < header.length; i++)
              headerCell(header[i], align(i)),
          ]),
          for (final cells in rows)
            row([
              for (var i = 0; i < cells.length; i++)
                Text(
                  cells[i],
                  style: style,
                  textAlign: align(i),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ]),
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

/// The name of a detail kind, see `GameRecord.details`.
String _detailName(BuildContext context, String kind) => switch (kind) {
  'weis' => context.l10n.weis,
  'handWeis' => context.l10n.handWeis,
  'tableWeis' => context.l10n.tableWeis,
  _ => kind,
};

/// The icon of a detail kind as the board shows it, if it has one.
String? _detailIcon(String kind) => switch (kind) {
  'handWeis' => 'assets/actions/hand_weis.svg',
  'tableWeis' => 'assets/actions/table_weis.svg',
  _ => null,
};
