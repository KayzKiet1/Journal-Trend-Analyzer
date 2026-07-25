import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/models/managed_collection.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'firestore_manager_view_model.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  late final FirestoreManagerViewModel _viewModel;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _viewModel = FirestoreManagerViewModel()..loadCollections();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Quản lý cơ sở dữ liệu',
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.collections.isEmpty) {
            return const LoadingView();
          }

          if (_viewModel.errorMessage != null &&
              _viewModel.collections.isEmpty) {
            return ErrorView(message: _viewModel.errorMessage!);
          }

          final filteredCollections = _viewModel.collections
              .where(
                (c) =>
                    !_hiddenCollectionNames.contains(c.name) &&
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

          return RefreshIndicator(
            onRefresh: _viewModel.loadCollections,
            child: ListView(
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 700 ? 20 : 32,
              ),
              children: [
                _buildHeader(context),
                const SizedBox(height: 28),
                if (filteredCollections.isEmpty)
                  _buildEmptyState()
                else
                  _buildCollectionGrid(context, filteredCollections),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.brightness == Brightness.dark
        ? Colors.white
        : colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách collection',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ hiển thị collection nghiệp vụ ổn định để kiểm tra dữ liệu demo.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _viewModel.isLoading
                  ? null
                  : _viewModel.loadCollections,
              icon: _viewModel.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới dữ liệu',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: colorScheme.primary,
                fixedSize: const Size(48, 48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Search Bar
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm collection...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              fillColor: colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionGrid(
    BuildContext context,
    List<ManagedCollection> collections,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1240
            ? 4
            : width >= 880
            ? 3
            : width >= 580
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 128,
          ),
          itemCount: collections.length,
          itemBuilder: (context, index) =>
              _CollectionCard(collection: collections[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy collection nào khớp với từ khóa.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatefulWidget {
  const _CollectionCard({required this.collection});
  final ManagedCollection collection;

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final purpose = _collectionPurposes[widget.collection.name];
    final bool isCritical = ['users'].contains(widget.collection.name);
    final bool isConfig =
        widget.collection.name.contains('config') ||
        widget.collection.name.contains('health');

    final Color accentColor = isCritical
        ? const Color(0xFF6366F1)
        : (isConfig ? const Color(0xFFF59E0B) : const Color(0xFF64748B));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
          AdminRoutes.firestoreDocuments,
          arguments: widget.collection.name,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? accentColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 15 : 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.1),
                      accentColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isCritical
                        ? Icons.storage_rounded
                        : (isConfig
                              ? Icons.settings_rounded
                              : Icons.folder_shared_rounded),
                    color: accentColor,
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.collection.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    if (purpose != null) ...[
                      Tooltip(
                        message: purpose,
                        waitDuration: const Duration(milliseconds: 400),
                        child: Text(
                          purpose,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.collection.count} tài liệu',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _isHovered
                    ? accentColor
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _collectionPurposes = {
  'users': 'Hồ sơ người dùng và dữ liệu con theo tài khoản.',
  'app_config': 'Cấu hình nội bộ lưu trong Firestore.',
  'analytics_events': 'Event từ mobile app để admin analytics tổng hợp.',
  'notificationLogs': 'Lịch sử gửi notification.',
  'auditLogs': 'Log thao tác admin.',
  'app_errors': 'Lỗi app tự ghi để theo dõi sức khỏe hệ thống.',
  'function_errors': 'Lỗi Cloud Functions tự ghi nếu có.',
  'system_health': 'Trạng thái và cảnh báo hệ thống.',
};

const _hiddenCollectionNames = {'journals', 'publications'};
