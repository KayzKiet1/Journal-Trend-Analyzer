import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/journal_model.dart';
import '../models/publication_model.dart';
import '../models/trend_data_model.dart';
import '../controllers/journal_library_controller.dart';
import '../services/openalex_service.dart';
import '../controllers/publication_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_text_styles.dart';
import '../widgets/publication_card.dart';
import '../widgets/year_trend_chart.dart';
import '../widgets/loading_widget.dart';
import 'publication_detail_screen.dart';

class JournalDetailScreen extends StatefulWidget {
  final String journalId;
  final String journalName;

  const JournalDetailScreen({
    super.key,
    required this.journalId,
    required this.journalName,
  });

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  bool _isLoading = true;
  Journal? _journal;
  List<Publication> _works = [];
  List<TrendData> _trends = [];
  List<Map<String, dynamic>> _topTopics = [];
  int _currentPage = 1;
  int _totalWorks = 0;
  bool _isWorksLoading = false;
  final int _perPage = 10;
  final ScrollController _scrollController = ScrollController();
  final OpenAlexService _apiService = OpenAlexService();

  // Filter and Search states
  final TextEditingController _searchController = TextEditingController();
  int? _selectedYear;
  int? _minCitations;
  final List<int> _citationOptions = [0, 10, 50, 100, 500, 1000];

  // Sorting states
  String _sortField = 'publication_year';
  bool _isDescending = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getJournalDetails(widget.journalId),
        _apiService.getWorksByJournal(widget.journalId, page: 1),
        _apiService.getJournalYearlyTrend(widget.journalId),
        _apiService.getJournalTopTopics(widget.journalId),
      ]);

      setState(() {
        _journal = results[0] as Journal;
        final worksData = results[1] as Map<String, dynamic>;
        _works = worksData['results'];
        _totalWorks = worksData['total_count'];
        _trends = results[2] as List<TrendData>;
        _topTopics = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
      if (mounted && _journal != null) {
        context.read<JournalLibraryController>().addRecentViewed(_journal!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
      }
    }
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || (page - 1) * _perPage >= _totalWorks) return;

    setState(() {
      _isWorksLoading = true;
      _currentPage = page;
    });

    try {
      final worksData = await _apiService.getWorksByJournal(
        widget.journalId,
        page: _currentPage,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        year: _selectedYear,
        minCitations: _minCitations,
        sortField: _sortField,
        descending: _isDescending,
      );
      setState(() {
        _works = worksData['results'];
        _totalWorks = worksData['total_count'];
        _isWorksLoading = false;
      });
      // Scroll back up to the start of the works list
      // Note: In a SingleChildScrollView, we might need a more complex logic if we want to scroll to a specific widget
    } catch (e) {
      setState(() => _isWorksLoading = false);
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể mở liên kết')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingWidget());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.book_outlined, size: 20),
            const SizedBox(width: 8),
            const Text('Source', style: TextStyle(fontSize: 16)),
          ],
        ),
        elevation: 0,
        actions: [
          if (_journal != null)
            Consumer<JournalLibraryController>(
              builder: (context, library, child) {
                final isFavorite = library.isFavorite(_journal!.id);
                return IconButton(
                  tooltip: isFavorite ? 'Bỏ lưu journal' : 'Lưu journal',
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  onPressed: () => library.toggleFavorite(_journal!),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _journal?.name ?? widget.journalName,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.md),

                // Analysis Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _journal == null
                        ? null
                        : () {
                            final controller = context
                                .read<PublicationController>();
                            controller.setLastAnalysis(_journal, _trends);
                            controller.setSelectedIndex(2);
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analyze Journal Trends'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Top section: Re-integrating layout to match screenshot
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 700;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoCard(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildWorksList(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildStatsCard(),
                                const SizedBox(height: AppSpacing.lg),
                                YearTrendChart(trends: _trends),
                                const SizedBox(height: AppSpacing.lg),
                                _buildTopicList(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildStatsCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildInfoCard(),
                          const SizedBox(height: AppSpacing.lg),
                          YearTrendChart(trends: _trends),
                          const SizedBox(height: AppSpacing.lg),
                          _buildTopicList(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildWorksList(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Homepage', _journal?.homepageUrl, isLink: true),
          _buildInfoRow('ISSNs', _journal?.issns.join(', ')),
          _buildInfoRow('Source type', _journal?.type),
          _buildInfoRow('Publisher', _journal?.publisher),
          _buildInfoRow('Alternate names', _journal?.alternateNames.join(', ')),
          const Divider(height: 32),
          _buildInfoRow(
            'Fully open access',
            _journal?.isOa == true ? 'Yes' : 'No',
          ),
          _buildInfoRow('In DOAJ', _journal?.isInDoaj == true ? 'Yes' : 'No'),
          _buildInfoRow(
            'Article Processing Charge',
            _journal?.apcUsd != null ? '\$${_journal!.apcUsd}' : 'Unknown',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: isLink ? () => _launchUrl(value) : null,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isLink ? AppColors.accent : AppColors.primary,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        children: [
          _buildStatItem('Works count', _journal?.worksCount.toString()),
          _buildStatItem('Citation count', _journal?.citedByCount.toString()),
          _buildStatItem(
            'H-index',
            _journal?.hIndex?.toString(),
            tooltip:
                'Chỉ số đo lường năng suất và tác động trích dẫn. Chỉ số h là số h bài báo có ít nhất h lượt trích dẫn.',
          ),
          _buildStatItem(
            'I10-index',
            _journal?.i10Index?.toString(),
            tooltip: 'Số lượng bài báo có ít nhất 10 lượt trích dẫn.',
          ),
          _buildStatItem(
            '2yr mean citedness',
            _journal?.twoYearMeanCitedness?.toStringAsFixed(3),
            tooltip:
                'Số lượng trích dẫn trung bình của các bài báo được xuất bản trong 2 năm gần nhất (Tương đương Impact Factor).',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String? value, {String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  showDuration: const Duration(seconds: 3),
                  triggerMode: TooltipTriggerMode.tap,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  textStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.background,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
          Text(value ?? '-', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildTopicList() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tag, size: 16),
              const SizedBox(width: 8),
              Text('Topic', style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ..._topTopics.map(
            (topic) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topic['name'],
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    topic['count'].toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isWorksLoading = true;
      _currentPage = 1;
    });

    try {
      final worksData = await _apiService.getWorksByJournal(
        widget.journalId,
        page: _currentPage,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        year: _selectedYear,
        minCitations: _minCitations,
        sortField: _sortField,
        descending: _isDescending,
      );
      setState(() {
        _works = worksData['results'];
        _totalWorks = worksData['total_count'];
        _isWorksLoading = false;
      });
    } catch (e) {
      setState(() => _isWorksLoading = false);
    }
  }

  Widget _buildWorksList() {
    int totalPages = (_totalWorks / _perPage).ceil();
    if (totalPages == 0 && _totalWorks > 0) totalPages = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT WORKS', style: AppTextStyles.labelCaps),
            if (_totalWorks > 0)
              Text(
                '$_totalWorks works',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFilterBar(),
        const SizedBox(height: AppSpacing.md),
        if (_isWorksLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _works.length,
            itemBuilder: (context, index) {
              final pub = _works[index];
              return PublicationCard(
                title: pub.title,
                authors: pub.authorsString,
                journal: pub.journalName,
                year: pub.publicationYear.toString(),
                citations: pub.citedByCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PublicationDetailScreen(publication: pub),
                    ),
                  );
                },
              );
            },
          ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildPaginationBar(totalPages),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    List<int> availableYears = _trends.map((t) => t.year).toSet().toList();
    availableYears.sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEARCH & FILTER',
            style: AppTextStyles.labelCaps.copyWith(fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên bài báo...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppColors.secondary,
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildLabeledDropdown<int?>(
                  label: 'NĂM XUẤT BẢN',
                  value: _selectedYear,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả', style: TextStyle(fontSize: 12)),
                    ),
                    ...availableYears.map(
                      (y) => DropdownMenuItem(
                        value: y,
                        child: Text(
                          y.toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedYear = val);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildLabeledDropdown<int?>(
                  label: 'LƯỢT TRÍCH DẪN',
                  value: _minCitations,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả', style: TextStyle(fontSize: 12)),
                    ),
                    ..._citationOptions
                        .where((opt) => opt > 0)
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(
                              '$opt+',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                  ],
                  onChanged: (val) {
                    setState(() => _minCitations = val);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildLabeledDropdown<String>(
                  label: 'SẮP XẾP THEO',
                  value: _sortField,
                  items: const [
                    DropdownMenuItem(
                      value: 'publication_year',
                      child: Text(
                        'Năm xuất bản',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cited_by_count',
                      child: Text(
                        'Lượt trích dẫn',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sortField = val);
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildLabeledDropdown<bool>(
                  label: 'THỨ TỰ',
                  value: _isDescending,
                  items: const [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Giảm dần', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Tăng dần', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _isDescending = val);
                      _applyFilters();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 9,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.secondary,
              ),
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Page $_currentPage of $totalPages',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: _currentPage < totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
