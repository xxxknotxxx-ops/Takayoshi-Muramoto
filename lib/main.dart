
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const TroublePadApp());

class TroublePadApp extends StatelessWidget {
  const TroublePadApp({super.key});

  TextTheme _bumpTextTheme(TextTheme base, double delta) {
    TextStyle? grow(TextStyle? s) {
      if (s == null) return null;
      final fs = s.fontSize ?? 14;
      return s.copyWith(fontSize: fs + delta);
    }

    return base.copyWith(
      displayLarge: grow(base.displayLarge),
      displayMedium: grow(base.displayMedium),
      displaySmall: grow(base.displaySmall),
      headlineLarge: grow(base.headlineLarge),
      headlineMedium: grow(base.headlineMedium),
      headlineSmall: grow(base.headlineSmall),
      titleLarge: grow(base.titleLarge),
      titleMedium: grow(base.titleMedium),
      titleSmall: grow(base.titleSmall),
      bodyLarge: grow(base.bodyLarge),
      bodyMedium: grow(base.bodyMedium),
      bodySmall: grow(base.bodySmall),
      labelLarge: grow(base.labelLarge),
      labelMedium: grow(base.labelMedium),
      labelSmall: grow(base.labelSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light().textTheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'トラブル対応パッド',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        textTheme: _bumpTextTheme(baseTheme, 4),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(fontSize: 18),
          floatingLabelStyle: TextStyle(fontSize: 18),
          hintStyle: TextStyle(fontSize: 16),
          helperStyle: TextStyle(fontSize: 14),
          errorStyle: TextStyle(fontSize: 14),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(fontSize: 18),
        ),
      ),
      home: const TroublePadHome(),
    );
  }
}

class TroubleRecord {
  final String id;
  final String ticketNo;
  final String occurredAt;
  final String customer;
  final String deviceNo;
  final String country;
  final String version;
  final String summary;
  final String detail;
  final String cause;
  final String solution;
  final String status;
  final String attachmentUrl;

  const TroubleRecord({
    required this.id,
    required this.ticketNo,
    required this.occurredAt,
    required this.customer,
    required this.deviceNo,
    required this.country,
    required this.version,
    required this.summary,
    required this.detail,
    required this.cause,
    required this.solution,
    required this.status,
    required this.attachmentUrl,
  });

  TroubleRecord copyWith({
    String? id,
    String? ticketNo,
    String? occurredAt,
    String? customer,
    String? deviceNo,
    String? country,
    String? version,
    String? summary,
    String? detail,
    String? cause,
    String? solution,
    String? status,
    String? attachmentUrl,
  }) {
    return TroubleRecord(
      id: id ?? this.id,
      ticketNo: ticketNo ?? this.ticketNo,
      occurredAt: occurredAt ?? this.occurredAt,
      customer: customer ?? this.customer,
      deviceNo: deviceNo ?? this.deviceNo,
      country: country ?? this.country,
      version: version ?? this.version,
      summary: summary ?? this.summary,
      detail: detail ?? this.detail,
      cause: cause ?? this.cause,
      solution: solution ?? this.solution,
      status: status ?? this.status,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketNo': ticketNo,
        'occurredAt': occurredAt,
        'customer': customer,
        'deviceNo': deviceNo,
        'country': country,
        'version': version,
        'summary': summary,
        'detail': detail,
        'cause': cause,
        'solution': solution,
        'status': status,
        'attachmentUrl': attachmentUrl,
      };

  factory TroubleRecord.fromJson(Map<String, dynamic> json) {
    return TroubleRecord(
      id: json['id'] as String? ?? '',
      ticketNo: json['ticketNo'] as String? ?? '',
      occurredAt: json['occurredAt'] as String? ?? '',
      customer: json['customer'] as String? ?? '',
      deviceNo: json['deviceNo'] as String? ?? '',
      country: json['country'] as String? ?? '',
      version: json['version'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      cause: json['cause'] as String? ?? '',
      solution: json['solution'] as String? ?? '',
      status: json['status'] as String? ?? '受付',
      attachmentUrl: json['attachmentUrl'] as String? ?? '',
    );
  }
}

enum _Screen { list, edit }

class TroublePadHome extends StatefulWidget {
  const TroublePadHome({super.key});

  @override
  State<TroublePadHome> createState() => _TroublePadHomeState();
}

class _TroublePadHomeState extends State<TroublePadHome>
    with TickerProviderStateMixin {
  final _occurredAt = TextEditingController();
  final _ticketNo = TextEditingController();
  final _customer = TextEditingController();
  final _deviceNo = TextEditingController();
  final _country = TextEditingController();
  final _version = TextEditingController();
  final _summary = TextEditingController();
  final _attachUrl = TextEditingController();
  final _detail = TextEditingController();
  final _cause = TextEditingController();
  final _solution = TextEditingController();
  final _search = TextEditingController();
  final _detailFocus = FocusNode();
  final _rand = Random();

  final List<String> _customerOptions = ['AM', 'DN', 'IN', 'IM', 'PH', 'SE', 'TC', 'KLA'];
  final List<String> _versionOptions = ['V1.0', 'V2.0', 'V3.0'];
  final List<String> _countryOptions = ['Japan', 'USA', 'Austria', 'Korea', 'TAIWAN', 'Germany'];
  final List<String> _statusOptions = ['受付', '進行中', '緊急対応', '様子見', '終了済'];

  static const Map<String, int> _statusOrder = {
    '緊急対応': 0,
    '受付': 1,
    '進行中': 2,
    '様子見': 3,
    '終了済': 4,
  };
  static const String _storageKeyRecords = 'trouble_records';
  static const String _storageKeyClosedAt = 'trouble_closed_at';

  List<TroubleRecord> _records = [];
  final Map<String, DateTime> _closedAt = {};
  final Map<String, String> _pendingStatus = {};
  String? _editingId;
  String? _selectedId;
  _Screen _screen = _Screen.list;

  bool _showCountryTabs = false;
  bool _showCustomerTabs = false;
  bool _showDeviceNoTabs = false;
  bool _showVersionTabs = false;
  bool _showStatusTabs = false;
  String? _countryPriority;
  String? _customerPriority;
  String? _deviceNoPriority;
  String? _versionPriority;
  String? _statusPriority;

  String? _editSnapshot;

  String _snapshotFields() => [
        _occurredAt.text,
        _ticketNo.text,
        _customer.text,
        _deviceNo.text,
        _country.text,
        _version.text,
        _summary.text,
        _attachUrl.text,
        _detail.text,
        _cause.text,
        _solution.text,
      ].join('␟');

  bool get _isDirty => _editSnapshot != _snapshotFields();

  @override
  void initState() {
    super.initState();
    _occurredAt.text = _nowString();
    _loadFromLocalStorage();
    _attachUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _occurredAt.dispose();
    _ticketNo.dispose();
    _customer.dispose();
    _deviceNo.dispose();
    _country.dispose();
    _version.dispose();
    _summary.dispose();
    _attachUrl.dispose();
    _detail.dispose();
    _cause.dispose();
    _solution.dispose();
    _search.dispose();
    _detailFocus.dispose();
    super.dispose();
  }

  void _memorizeSnapshot() => _editSnapshot = _snapshotFields();

  void _saveToLocalStorage() {
    final recordsJson = _records.map((record) => record.toJson()).toList();
    html.window.localStorage[_storageKeyRecords] = jsonEncode(recordsJson);

    final closedAtJson = _closedAt.map(
      (id, closedAt) => MapEntry(id, closedAt.toIso8601String()),
    );
    html.window.localStorage[_storageKeyClosedAt] = jsonEncode(closedAtJson);
  }

  void _loadFromLocalStorage() {
    final savedRecords = html.window.localStorage[_storageKeyRecords];
    if (savedRecords == null || savedRecords.isEmpty) {
      _records = _seedSamples();
      for (final record in _records) {
        if (record.status == '終了済') {
          _closedAt[record.id] = DateTime.now();
        }
      }
      _saveToLocalStorage();
      return;
    }

    try {
      final decoded = jsonDecode(savedRecords) as List<dynamic>;
      _records = decoded
          .whereType<Map>()
          .map((item) => TroubleRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _loadClosedAt();
    } catch (_) {
      _records = _seedSamples();
      _closedAt.clear();
      _saveToLocalStorage();
    }
  }

  void _loadClosedAt() {
    _closedAt.clear();
    final savedClosedAt = html.window.localStorage[_storageKeyClosedAt];
    if (savedClosedAt == null || savedClosedAt.isEmpty) return;

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(savedClosedAt));
      for (final entry in decoded.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) _closedAt[entry.key] = parsed;
      }
    } catch (_) {
      _closedAt.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _screen == _Screen.list ? _buildListScaffold() : _buildEditScaffold();
  }

  Widget _buildListScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トラブル対応パッド'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新規作成',
            onPressed: _startNewRecord,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: '検索（内容／詳細／原因／客先名など）',
                      border: const OutlineInputBorder(),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '入力をクリア',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('検索のリセット'),
                  onPressed: _search.text.isEmpty
                      ? null
                      : () {
                          _search.clear();
                          setState(() {});
                        },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _prioritySection('国', Icons.flag, _countryOptions, _countryPriority,
                    (v) => setState(() => _countryPriority = v), () => setState(() => _countryPriority = null),
                    show: _showCountryTabs, onToggle: () => setState(() => _showCountryTabs = !_showCountryTabs)),
                _prioritySection('客先名', Icons.business, _customerOptions, _customerPriority,
                    (v) => setState(() => _customerPriority = v), () => setState(() => _customerPriority = null),
                    show: _showCustomerTabs, onToggle: () => setState(() => _showCustomerTabs = !_showCustomerTabs)),
                _prioritySection('装置番号', Icons.memory, _deviceNoCandidates(), _deviceNoPriority,
                    (v) => setState(() => _deviceNoPriority = v), () => setState(() => _deviceNoPriority = null),
                    show: _showDeviceNoTabs, onToggle: () => setState(() => _showDeviceNoTabs = !_showDeviceNoTabs)),
                _prioritySection('装置Ver', Icons.tag, _versionOptions, _versionPriority,
                    (v) => setState(() => _versionPriority = v), () => setState(() => _versionPriority = null),
                    show: _showVersionTabs, onToggle: () => setState(() => _showVersionTabs = !_showVersionTabs)),
                _prioritySection('状態', Icons.assignment_turned_in, _statusOptions, _statusPriority,
                    (v) => setState(() => _statusPriority = v), () => setState(() => _statusPriority = null),
                    show: _showStatusTabs, onToggle: () => setState(() => _showStatusTabs = !_showStatusTabs)),
              ],
            ),
          ),
          Expanded(child: _listTable()),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'view-selected',
            onPressed: _selectedId == null ? null : () => _edit(_selectedId!),
            icon: const Icon(Icons.open_in_full),
            label: const Text('選択欄の詳細表示'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'copy-create',
            onPressed: _copyAndCreateFromSelected,
            icon: const Icon(Icons.copy_all),
            label: const Text('コピーして新規作成'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'new-create',
            onPressed: _startNewRecord,
            icon: const Icon(Icons.add),
            label: const Text('新規作成'),
          ),
        ],
      ),
    );
  }

  Widget _prioritySection(
    String title,
    IconData icon,
    List<String> chips,
    String? current,
    void Function(String?) onSelect,
    VoidCallback onClear, {
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: onToggle,
              icon: Icon(icon, size: 18),
              label: Text(show ? '$titleタブを閉じる' : '$titleタブを開く'),
            ),
            if (current != null) OutlinedButton(onPressed: onClear, child: const Text('優先:解除')),
          ],
        ),
        if (show)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final chip in chips)
                ChoiceChip(label: Text(chip), selected: current == chip, onSelected: (_) => onSelect(chip)),
              ChoiceChip(label: const Text('すべて'), selected: current == null, onSelected: (_) => onSelect(null)),
            ],
          ),
      ],
    );
  }

  Widget _buildEditScaffold() {
    return WillPopScope(
      onWillPop: () async {
        await _onAppBarBackPressed();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: '一覧へ戻る',
            onPressed: _onAppBarBackPressed,
          ),
          title: const Text('トラブル対応パッド'),
          actions: [IconButton(icon: const Icon(Icons.save), tooltip: '保存', onPressed: _save)],
        ),
        body: _singleEditBody(),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(_editingId == null ? '保存' : '更新'),
                  style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _cancelWithoutSave,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('キャンセル'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(220, 48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _singleEditBody() {
    const fieldTextStyle = TextStyle(fontSize: 18);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _occurredAt,
                  readOnly: true,
                  style: fieldTextStyle,
                  decoration: const InputDecoration(labelText: '発生日時', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _selectOccurredAt, icon: const Icon(Icons.calendar_today), label: const Text('選択')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _dropdownField(label: '国', options: _countryOptions, value: _country.text, onChanged: (v) => setState(() => _country.text = v))),
              const SizedBox(width: 8),
              Expanded(child: _dropdownField(label: '客先名', options: _customerOptions, value: _customer.text, onChanged: (v) => setState(() => _customer.text = v))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _deviceNo, style: fieldTextStyle, decoration: const InputDecoration(labelText: '装置番号', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: _dropdownField(label: '装置バージョン', options: _versionOptions, value: _version.text, onChanged: (v) => setState(() => _version.text = v))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _ticketNo, style: fieldTextStyle, decoration: const InputDecoration(labelText: 'Ticket No.', border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _summary,
            style: fieldTextStyle,
            decoration: const InputDecoration(labelText: 'トラブル内容（要約・タイトル）*', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _attachUrl,
                  style: fieldTextStyle,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: '添付ファイルURL（貼り付け可）', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _pickAttachmentPath, icon: const Icon(Icons.attach_file), label: const Text('添付')),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _attachUrl.text.trim().isEmpty ? null : () => _openUrl(_attachUrl.text.trim()),
                icon: const Icon(Icons.open_in_new),
                label: const Text('開く'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('トラブル詳細'),
          _bigPad(_detail, '事象、再現手順、頻度、スコープ、ログ抜粋など'),
          const SizedBox(height: 12),
          _sectionTitle('原因'),
          _bigPad(_cause, '一次原因／真因・切り分け結果・根拠'),
          const SizedBox(height: 12),
          _sectionTitle('改善方法'),
          _bigPad(_solution, '暫定対応／恒久対策／再発防止策'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right, size: 20),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      );

  Widget _bigPad(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      focusNode: identical(controller, _detail) ? _detailFocus : null,
      style: const TextStyle(fontSize: 18),
      minLines: 4,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
    );
  }

  Widget _dropdownField({
    required String label,
    required List<String> options,
    required void Function(String) onChanged,
    String? value,
  }) {
    final normalizedValue = value == null || value.isEmpty ? null : value;
    return DropdownButtonFormField<String>(
      value: normalizedValue,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 18)))).toList(),
      onChanged: (v) => onChanged(v ?? ''),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _listTable() {
    if (_filtered.isEmpty) return const Center(child: Text('記録がありません。'));

    const double wCountry = 80;
    const double wCustomer = 60;
    const double wDeviceNo = 90;
    const double wVersion = 70;
    const double wStatus = 210;
    const double wTime = 170;
    const double wDays = 80;
    const double wTicket = 140;
    const double wContent = 260;
    const double wCause = 260;

    Widget head(String text, double width) => SizedBox(width: width, child: Center(child: Text(text, overflow: TextOverflow.ellipsis)));
    Widget cellCenter(String text, double width) => SizedBox(
          width: width,
          child: Center(child: Text(text.isEmpty ? '-' : text, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
        );
    Widget cellLeft(String text, double width) => SizedBox(width: width, child: Text(text.isEmpty ? '-' : text, overflow: TextOverflow.ellipsis));

    final data = _applyPrioritySort(_filtered);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: head('国', wCountry)),
          DataColumn(label: head('客先', wCustomer)),
          DataColumn(label: head('装置番号', wDeviceNo)),
          DataColumn(label: head('Ver', wVersion)),
          DataColumn(label: head('状態', wStatus)),
          DataColumn(label: head('発生日', wTime)),
          DataColumn(label: head('経過日', wDays)),
          DataColumn(label: head('Ticket No.', wTicket)),
          DataColumn(label: head('内容', wContent)),
          DataColumn(label: head('原因', wCause)),
        ],
        rows: data.map((record) {
          final shownStatus = _pendingStatus[record.id] ?? record.status;
          final end = shownStatus == '終了済' ? (_closedAt[record.id] ?? DateTime.now()) : DateTime.now();
          final days = max(0, end.difference(_parseDt(record.occurredAt)).inDays);

          return DataRow(
            selected: _selectedId == record.id,
            onSelectChanged: (_) => setState(() => _selectedId = _selectedId == record.id ? null : record.id),
            color: MaterialStateProperty.resolveWith(
              (_) => _selectedId == record.id ? Colors.lightBlue.shade50 : _rowBgColor(shownStatus),
            ),
            cells: [
              DataCell(cellCenter(record.country, wCountry)),
              DataCell(cellCenter(record.customer, wCustomer)),
              DataCell(cellCenter(record.deviceNo, wDeviceNo)),
              DataCell(cellCenter(record.version, wVersion)),
              DataCell(_statusCell(record, shownStatus, wStatus)),
              DataCell(cellCenter(record.occurredAt, wTime)),
              DataCell(cellCenter('$days日', wDays)),
              DataCell(cellCenter(record.ticketNo, wTicket)),
              DataCell(GestureDetector(onDoubleTap: () => _edit(record.id), child: cellLeft(record.summary, wContent))),
              DataCell(cellLeft(record.cause, wCause)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _statusCell(TroubleRecord record, String shownStatus, double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: shownStatus,
              items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _pendingStatus[record.id] = v);
              },
            ),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: _pendingStatus[record.id] == null
                ? null
                : () {
                    _setStatus(record.id, _pendingStatus[record.id]!);
                    _pendingStatus.remove(record.id);
                  },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  List<TroubleRecord> _applyPrioritySort(List<TroubleRecord> src) {
    final list = List<TroubleRecord>.from(src);
    int prefScore(String? key, String field) => key == null ? 0 : (field == key ? 0 : 1);
    list.sort((a, b) {
      var c = prefScore(_countryPriority, a.country) - prefScore(_countryPriority, b.country);
      if (c != 0) return c;
      c = prefScore(_customerPriority, a.customer) - prefScore(_customerPriority, b.customer);
      if (c != 0) return c;
      c = prefScore(_deviceNoPriority, a.deviceNo) - prefScore(_deviceNoPriority, b.deviceNo);
      if (c != 0) return c;
      c = prefScore(_versionPriority, a.version) - prefScore(_versionPriority, b.version);
      if (c != 0) return c;
      c = prefScore(_statusPriority, a.status) - prefScore(_statusPriority, b.status);
      if (c != 0) return c;
      c = (_statusOrder[a.status] ?? 999) - (_statusOrder[b.status] ?? 999);
      if (c != 0) return c;
      return _parseDt(b.occurredAt).compareTo(_parseDt(a.occurredAt));
    });
    return list;
  }

  List<String> _deviceNoCandidates() {
    final set = <String>{};
    for (final record in _records) {
      final deviceNo = record.deviceNo.trim();
      if (deviceNo.isNotEmpty) set.add(deviceNo);
    }
    final list = set.toList()..sort();
    return list.take(24).toList();
  }

  List<TroubleRecord> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records.where((record) {
      final fields = [
        record.ticketNo,
        record.summary,
        record.detail,
        record.cause,
        record.solution,
        record.customer,
        record.deviceNo,
        record.country,
        record.version,
        record.status,
        record.attachmentUrl,
      ];
      return fields.any((text) => text.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _selectOccurredAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _occurredAt.text = _fmt(dt));
  }

  Future<void> _pickAttachmentPath() async {
    final controller = TextEditingController(text: _attachUrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('資料パスを入力'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '資料パス（相対パス）', hintText: '例：17. 全体会議/議事録.xlsx'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    setState(() => _attachUrl.text = result);
  }

  void _openUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'blob'))) {
      _showSnack('無効なURLです');
      return;
    }
    html.window.open(url, '_blank');
  }

  void _setStatus(String id, String status) {
    setState(() {
      _records = _records.map((record) => record.id == id ? record.copyWith(status: status) : record).toList();
      if (status == '終了済') {
        _closedAt[id] = _closedAt[id] ?? DateTime.now();
      } else {
        _closedAt.remove(id);
      }
    });
    _saveToLocalStorage();
  }

  Color _rowBgColor(String status) {
    switch (status) {
      case '進行中':
        return Colors.green.shade50;
      case '緊急対応':
        return Colors.red.shade50;
      case '様子見':
        return Colors.amber.shade50;
      case '終了済':
        return Colors.blueGrey.shade50;
      case '受付':
      default:
        return Colors.blue.shade100;
    }
  }

  void _save() {
    if (_summary.text.trim().isEmpty) {
      _showSnack('『トラブル内容』は必須です');
      return;
    }

    var status = '受付';
    if (_editingId != null) {
      final old = _records.where((record) => record.id == _editingId);
      if (old.isNotEmpty) status = old.first.status;
    }

    final rec = TroubleRecord(
      id: _editingId ?? _genId(),
      ticketNo: _ticketNo.text.trim(),
      occurredAt: _occurredAt.text,
      customer: _customer.text,
      deviceNo: _deviceNo.text.trim(),
      country: _country.text,
      version: _version.text,
      summary: _summary.text.trim(),
      detail: _detail.text,
      cause: _cause.text,
      solution: _solution.text,
      status: status,
      attachmentUrl: _attachUrl.text.trim(),
    );

    setState(() {
      if (_editingId == null) {
        _records.insert(0, rec);
      } else {
        _records = _records.map((record) => record.id == _editingId ? rec : record).toList();
      }
      _screen = _Screen.list;
      _resetDraft();
    });
    _saveToLocalStorage();
    _showSnack('保存しました');
  }

  void _startNewRecord() {
    setState(() {
      _resetDraft();
      _screen = _Screen.edit;
      _memorizeSnapshot();
    });
    Future.microtask(() => _detailFocus.requestFocus());
  }

  void _resetDraft() {
    _editingId = null;
    _occurredAt.text = _nowString();
    _ticketNo.clear();
    _customer.clear();
    _deviceNo.clear();
    _country.clear();
    _version.clear();
    _summary.clear();
    _attachUrl.clear();
    _detail.clear();
    _cause.clear();
    _solution.clear();
    _editSnapshot = null;
  }

  void _edit(String id) {
    final rec = _records.firstWhere((record) => record.id == id);
    setState(() {
      _editingId = rec.id;
      _occurredAt.text = rec.occurredAt;
      _ticketNo.text = rec.ticketNo;
      _customer.text = rec.customer;
      _deviceNo.text = rec.deviceNo;
      _country.text = rec.country;
      _version.text = rec.version;
      _summary.text = rec.summary;
      _attachUrl.text = rec.attachmentUrl;
      _detail.text = rec.detail;
      _cause.text = rec.cause;
      _solution.text = rec.solution;
      _screen = _Screen.edit;
      _memorizeSnapshot();
    });
    Future.microtask(() => _detailFocus.requestFocus());
  }

  void _copyAndCreateFromSelected() {
    if (_selectedId == null) {
      _showSnack('コピー元の行を選択してください');
      return;
    }
    final src = _records.firstWhere((record) => record.id == _selectedId);
    setState(() {
      _editingId = null;
      _occurredAt.text = _nowString();
      _ticketNo.text = src.ticketNo;
      _customer.clear();
      _deviceNo.clear();
      _country.clear();
      _version.text = src.version;
      _summary.text = src.summary;
      _attachUrl.clear();
      _detail.text = src.detail;
      _cause.text = src.cause;
      _solution.text = src.solution;
      _screen = _Screen.edit;
      _memorizeSnapshot();
    });
    Future.microtask(() => _detailFocus.requestFocus());
  }

  Future<void> _onAppBarBackPressed() async {
    final ok = await _confirmDiscardIfNeeded();
    if (!ok) return;
    setState(() {
      _screen = _Screen.list;
      _resetDraft();
    });
  }

  Future<void> _cancelWithoutSave() async {
    final ok = await _confirmDiscardIfNeeded();
    if (!ok) return;
    setState(() {
      _screen = _Screen.list;
      _resetDraft();
    });
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_isDirty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('更新せずにキャンセルしますか？'),
        content: const Text('編集内容は保存されません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('いいえ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('はい')),
        ],
      ),
    );
    return res == true;
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _nowString() => _fmt(DateTime.now());

  String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  DateTime _parseDt(String s) {
    try {
      final y = int.parse(s.substring(0, 4));
      final m = int.parse(s.substring(5, 7));
      final d = int.parse(s.substring(8, 10));
      final hh = int.parse(s.substring(11, 13));
      final mm = int.parse(s.substring(14, 16));
      return DateTime(y, m, d, hh, mm);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _genId() => 'id${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(100000)}';

  List<TroubleRecord> _seedSamples() {
    final now = DateTime.now();
    String fm(DateTime dt) => _fmt(dt);
    return [
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0001', occurredAt: fm(now.subtract(const Duration(hours: 2))), customer: 'AM', deviceNo: 'EB-142', country: 'Japan', version: 'V3.0', summary: '露光ステージ原点復帰エラー (E5012)', detail: '原点復帰シーケンス中にX軸がリミットへ到達。再現は低頻度（1/30）。', cause: 'リミットセンサーの接触不良と配線テンション。', solution: 'コネクタ再圧着・配線ルート見直し・センサー交換。', status: '進行中', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0002', occurredAt: fm(now.subtract(const Duration(days: 1, hours: 3))), customer: 'DN', deviceNo: 'CLN-3201', country: 'USA', version: 'V2.0', summary: '真空リーク疑い', detail: '到達圧が頭打ち。Heリークで微小反応。', cause: 'ドアOリング座面の微傷とグリース不足。', solution: 'Oリング交換と座面ラッピング、手順見直し。', status: '終了済', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0003', occurredAt: fm(now.subtract(const Duration(days: 3, hours: 6))), customer: 'IN', deviceNo: 'ALN-77', country: 'Germany', version: 'V3.0', summary: 'アライメントNG', detail: '読取率が一時低下、照明再調整で回復。', cause: '照明ユニット劣化＋撮像窓の汚れ。', solution: '照明交換・窓清掃・しきい値最適化。', status: '様子見', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0004', occurredAt: fm(now.subtract(const Duration(days: 7))), customer: 'PH', deviceNo: 'DEV-509', country: 'TAIWAN', version: 'V1.0', summary: '温調系オーバーシュート', detail: 'ゲイン更新後に+2.5℃のオーバーシュート。', cause: '装置固有熱容量に対しゲイン過大。', solution: '自動同定→反映、I成分調整。', status: '受付', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0005', occurredAt: fm(now.subtract(const Duration(hours: 5))), customer: 'SE', deviceNo: 'CMP-221', country: 'Japan', version: 'V2.0', summary: 'UIフリーズ', detail: 'レシピ切替直後に無応答、I/O待ちブロック。', cause: 'ファイルロック競合。', solution: 'スコープ縮小＋非同期化、パッチ適用。', status: '緊急対応', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0006', occurredAt: fm(now.subtract(const Duration(days: 1))), customer: 'AM', deviceNo: 'EX-201', country: 'Japan', version: 'V3.0', summary: '照明ユニフォーミティ低下', detail: '中央-3%を検出。膜厚ムラ相関調査中。', cause: '光学ミラーの微汚れorコーティング劣化。', solution: '清掃・必要箇所交換、監視実装。', status: '進行中', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0007', occurredAt: fm(now.subtract(const Duration(days: 2, hours: 4))), customer: 'DN', deviceNo: 'EX-332', country: 'USA', version: 'V2.0', summary: 'ステージ位置決めずれ', detail: '再試行で改善するがタクト悪化。', cause: '温度ドリフト補正未適用＋センサ微オフセット。', solution: '再キャリブレーション＆適用、補正自動化。', status: '様子見', attachmentUrl: ''),
      TroubleRecord(id: _genId(), ticketNo: 'TCK-0008', occurredAt: fm(now.subtract(const Duration(days: 7, hours: 6))), customer: 'IN', deviceNo: 'EX-450', country: 'Germany', version: 'V3.0', summary: 'マスクアライメント不良', detail: 'オーバーレイ誤差が規定の1.5倍。', cause: '真空クランプ圧低下／ピン摩耗。', solution: 'リーク修理とピン交換、監視追加。', status: '緊急対応', attachmentUrl: ''),
    ];
  }
}
