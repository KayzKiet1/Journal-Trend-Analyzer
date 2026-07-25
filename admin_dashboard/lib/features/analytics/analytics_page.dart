import 'package:flutter/material.dart';

import '../../data/models/analytics_summary.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'analytics_view_model.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late final AnalyticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AnalyticsViewModel()..loadSummary();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Analytics',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.summary == null) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null && _viewModel.summary == null) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          final summary = _viewModel.summary;
          if (summary == null) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: _viewModel.loadSummary,
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                _AnalyticsHeader(
                  selectedDays: _viewModel.selectedDays,
                  isLoading: _viewModel.isLoading,
                  onDaysChanged: (days) => _viewModel.loadSummary(days: days),
                ),
                const SizedBox(height: 16),
                _MetricGrid(summary: summary),
                const SizedBox(height: 16),
                _AnalyticsChartGrid(summary: summary),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 900;
                    final topEvents = _RankPanel(
                      title: 'Top events',
                      icon: Icons.bolt_outlined,
                      items: summary.topEvents,
                    );
                    final topJournals = _RankPanel(
                      title: 'Top journals/searches',
                      icon: Icons.menu_book_outlined,
                      items: summary.topJournals,
                    );

                    if (!twoColumns) {
                      return Column(
                        children: [
                          topEvents,
                          const SizedBox(height: 16),
                          topJournals,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: topEvents),
                        const SizedBox(width: 16),
                        Expanded(child: topJournals),
                      ],
                    );
                  },
                ),
                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.selectedDays,
    required this.isLoading,
    required this.onDaysChanged,
  });

  final int selectedDays;
  final bool isLoading;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.analytics, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product analytics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dữ liệu lấy từ analytics_events đã aggregate qua Cloud Functions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7d')),
                ButtonSegment(value: 30, label: Text('30d')),
                ButtonSegment(value: 90, label: Text('90d')),
              ],
              selected: {selectedDays},
              onSelectionChanged: isLoading
                  ? null
                  : (value) => onDaysChanged(value.single),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricTile(
          label: 'Events',
          value: '${summary.totalEvents}',
          icon: Icons.touch_app_outlined,
        ),
        _MetricTile(
          label: 'Active users',
          value: '${summary.activeUsers}',
          icon: Icons.people_alt_outlined,
        ),
        _MetricTile(
          label: 'Today active',
          value: '${summary.activeUsersToday}',
          icon: Icons.today_outlined,
        ),
        _MetricTile(
          label: '7d active',
          value: '${summary.activeUsers7d}',
          icon: Icons.date_range_outlined,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsChartGrid extends StatelessWidget {
  const _AnalyticsChartGrid({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final dailyValues = summary.dailyEvents
        .map((event) => ChartPoint(label: event.date, value: event.count))
        .toList();

    var runningTotal = 0;
    final cumulativeValues = summary.dailyEvents.map((event) {
      runningTotal += event.count;
      return ChartPoint(label: event.date, value: runningTotal);
    }).toList();

    final topEventValues = summary.topEvents
        .map((event) => ChartPoint(label: event.name, value: event.count))
        .toList();

    final topJournalValues = summary.topJournals
        .map((journal) => ChartPoint(label: journal.name, value: journal.count))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 980;
        final cards = [
          _LineChartPanel(
            title: 'Xu hướng events theo ngày',
            subtitle: 'Số event ghi nhận từng ngày trong khoảng đã chọn.',
            icon: Icons.show_chart_rounded,
            points: dailyValues,
            color: Theme.of(context).colorScheme.primary,
          ),
          _LineChartPanel(
            title: 'Events tích lũy',
            subtitle: 'Tổng event cộng dồn, giúp nhìn tốc độ tăng hoạt động.',
            icon: Icons.trending_up_rounded,
            points: cumulativeValues,
            color: const Color(0xFF0F766E),
          ),
          _LineChartPanel(
            title: 'Phân bố top events',
            subtitle: 'Độ chênh giữa các loại event được dùng nhiều nhất.',
            icon: Icons.bolt_outlined,
            points: topEventValues,
            color: const Color(0xFFB45309),
          ),
          _LineChartPanel(
            title: 'Phân bố journals/searches',
            subtitle: 'Các journal hoặc từ khóa search xuất hiện nhiều nhất.',
            icon: Icons.menu_book_outlined,
            points: topJournalValues,
            color: const Color(0xFF2563EB),
          ),
        ];

        if (!twoColumns) {
          return Column(
            children: [
              for (final card in cards) ...[card, const SizedBox(height: 16)],
            ]..removeLast(),
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 16),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LineChartPanel extends StatelessWidget {
  const _LineChartPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.points,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxValue = points.fold<int>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  maxValue == 0 ? '-' : '$maxValue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (points.isEmpty)
              Text(
                'Chưa có dữ liệu để vẽ chart.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else ...[
              SizedBox(
                height: 220,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    points: points,
                    color: color,
                    gridColor: colorScheme.outlineVariant,
                    labelColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ChartLegend(points: points, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.points, required this.color});

  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final first = points.first.label;
    final last = points.last.label;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            first == last ? first : '$first  →  $last',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class ChartPoint {
  const ChartPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.labelColor,
  });

  final List<ChartPoint> points;
  final Color color;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 42.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 34.0;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = chartRect.top + chartRect.height * i / 3;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final maxValue = points.fold<int>(
      1,
      (max, point) => point.value > max ? point.value : max,
    );

    _drawLabel(canvas, '$maxValue', Offset(0, chartRect.top - 2), labelColor);
    _drawLabel(canvas, '0', Offset(0, chartRect.bottom - 12), labelColor);

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * i / (points.length - 1);
      final y =
          chartRect.bottom - (points[i].value / maxValue) * chartRect.height;
      offsets.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(offsets.first.dx, chartRect.bottom);
    for (final offset in offsets) {
      fillPath.lineTo(offset.dx, offset.dy);
    }
    fillPath.lineTo(offsets.last.dx, chartRect.bottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.02)],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      final previous = offsets[i - 1];
      final current = offsets[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = color;
    final pointStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, pointPaint);
      canvas.drawCircle(offset, 4, pointStrokePaint);
    }

    if (points.isNotEmpty) {
      _drawBottomLabel(canvas, points.first.label, chartRect.bottom + 10);
      if (points.length > 1) {
        _drawBottomLabel(
          canvas,
          points.last.label,
          chartRect.bottom + 10,
          alignRight: true,
          chartRight: chartRect.right,
        );
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 36);
    painter.paint(canvas, offset);
  }

  void _drawBottomLabel(
    Canvas canvas,
    String text,
    double y, {
    bool alignRight = false,
    double chartRight = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 120);
    final x = alignRight ? chartRight - painter.width : 42.0;
    painter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}

class _RankPanel extends StatelessWidget {
  const _RankPanel({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<CountMetric> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No data yet.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              )
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(item.name, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '${item.count}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
