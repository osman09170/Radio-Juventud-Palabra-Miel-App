import 'package:flutter/material.dart';
import '../services/alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with WidgetsBindingObserver {
  List<AlarmModel> _alarms = [];
  bool _loading = true;
  bool _hasExactPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Recarga cuando la app vuelve al frente (p.ej. tras dar permisos)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _init() async {
    await Future.wait([_load(), _checkPermission()]);
  }

  Future<void> _load() async {
    final alarms = await AlarmService.getAlarms();
    if (!mounted) return;
    setState(() { _alarms = alarms; _loading = false; });
  }

  Future<void> _checkPermission() async {
    final ok = await AlarmPermissions.canScheduleExact();
    if (!mounted) return;
    setState(() => _hasExactPermission = ok);
  }

  // ── Helpers de tiempo ──────────────────────────────────────────────────

  String _timeUntil(AlarmModel alarm) {
    if (!alarm.enabled) return 'desactivada';
    final next = AlarmService.nextAlarmTime(alarm);
    final diff = next.difference(DateTime.now());
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h == 0 && m == 0) return 'ahora';
    if (h == 0) return 'en ${m}min';
    if (m == 0) return 'en ${h}h';
    return 'en ${h}h ${m}min';
  }

  // ── Flujo agregar / editar ─────────────────────────────────────────────

  Future<void> _addAlarm() async {
    if (!_hasExactPermission) {
      await _showPermissionDialog();
      return;
    }
    final time = await _pickTime(TimeOfDay.now());
    if (time == null || !mounted) return;
    final alarm = await _showConfigSheet(time, null);
    if (alarm == null || !mounted) return;

    setState(() {
      _alarms = [..._alarms, alarm]
        ..sort((a, b) => a.hour != b.hour
            ? a.hour.compareTo(b.hour)
            : a.minute.compareTo(b.minute));
    });
    await AlarmService.addAlarm(alarm);
    _showSnack('Alarma ${alarm.formattedTime} · ${_timeUntil(alarm)}');
  }

  Future<void> _editAlarm(AlarmModel existing) async {
    if (!_hasExactPermission) {
      await _showPermissionDialog();
      return;
    }
    final time = await _pickTime(existing.time);
    if (time == null || !mounted) return;
    final updated = await _showConfigSheet(time, existing);
    if (updated == null || !mounted) return;

    // Eliminar vieja y agregar nueva (mismo ID)
    await AlarmService.deleteAlarm(existing.id);
    final withSameId = AlarmModel(
      id: existing.id,
      hour: updated.hour,
      minute: updated.minute,
      enabled: true,
      repeat: updated.repeat,
      days: updated.days,
      vibrate: updated.vibrate,
    );
    await AlarmService.addAlarm(withSameId);
    await _load();
    _showSnack('Alarma actualizada · ${_timeUntil(withSameId)}');
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF9AD5),
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A2E),
            onSurface: Colors.white,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: const Color(0xFF1A1A2E),
            hourMinuteColor: Colors.white.withValues(alpha: 0.1),
            hourMinuteTextColor: Colors.white,
            dialBackgroundColor: Colors.white.withValues(alpha: 0.08),
            dialHandColor: const Color(0xFFFF9AD5),
            dialTextColor: Colors.white,
            entryModeIconColor: const Color(0xFFFF9AD5),
          ),
        ),
        child: child!,
      ),
    );
  }

  Future<AlarmModel?> _showConfigSheet(TimeOfDay time, AlarmModel? existing) {
    return showModalBottomSheet<AlarmModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlarmConfigSheet(time: time, existing: existing),
    );
  }

  // ── Operaciones ──────────────────────────────────────────────────────────

  Future<void> _toggle(AlarmModel alarm, bool value) async {
    if (value && !_hasExactPermission) {
      await _showPermissionDialog();
      return;
    }
    setState(() {
      final idx = _alarms.indexWhere((a) => a.id == alarm.id);
      if (idx != -1) _alarms[idx] = alarm.copyWith(enabled: value);
    });
    await AlarmService.toggleAlarm(alarm.id, value);
  }

  Future<void> _delete(AlarmModel alarm) async {
    setState(() => _alarms.removeWhere((a) => a.id == alarm.id));
    await AlarmService.deleteAlarm(alarm.id);
    if (mounted) _showSnack('Alarma eliminada');
  }

  Future<bool> _confirmDelete(AlarmModel alarm) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Eliminar alarma',
                style: TextStyle(color: Colors.white)),
            content: Text(
              '¿Eliminar la alarma de las ${alarm.formattedTime}?',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white60)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showPermissionDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.alarm_on, color: Color(0xFFFF9AD5)),
            SizedBox(width: 10),
            Text('Permisos requeridos',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para que la alarma suene exactamente a la hora configurada, necesita 2 permisos:',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5),
            ),
            const SizedBox(height: 16),
            _permRow(Icons.schedule, '1. Alarmas exactas',
                'Permite programar la hora precisa'),
            const SizedBox(height: 10),
            _permRow(Icons.battery_saver, '2. Sin restricción de batería',
                'Evita que Android la duerma'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9AD5),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await AlarmPermissions.requestExact();
              await AlarmPermissions.openBatterySettings();
            },
            child: const Text('Dar permisos',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _permRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF9AD5), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              child: Row(
                children: [
                  const Icon(Icons.alarm,
                      color: Color(0xFFFF9AD5), size: 26),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alarmas',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      Text('Despierta con la radio',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // Banner de permisos (si falta)
            if (!_hasExactPermission)
              GestureDetector(
                onTap: _showPermissionDialog,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Faltan permisos para que la alarma suene. Toca para configurar.',
                          style: TextStyle(
                              color: Colors.orange, fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.orange, size: 18),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFF9AD5)))
                  : _alarms.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _alarms.length,
                          itemBuilder: (_, i) => _buildCard(_alarms[i]),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarm,
        backgroundColor: const Color(0xFFFF9AD5),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Nueva alarma',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_add_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 20),
          Text('Sin alarmas',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 20,
                  fontWeight: FontWeight.w300)),
          const SizedBox(height: 8),
          Text('Toca "Nueva alarma" para agregar',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 13)),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildCard(AlarmModel alarm) {
    return Dismissible(
      key: Key('alarm_${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 22),
            SizedBox(height: 4),
            Text('Eliminar',
                style: TextStyle(
                    color: Colors.redAccent, fontSize: 10)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(alarm),
      onDismissed: (_) => _delete(alarm),
      child: GestureDetector(
        onTap: () => _editAlarm(alarm),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
          decoration: BoxDecoration(
            color: alarm.enabled
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: alarm.enabled
                  ? const Color(0xFFFF9AD5).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hora grande
                    Text(
                      alarm.formattedTime,
                      style: TextStyle(
                        color: alarm.enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 42,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tiempo restante
                    Text(
                      _timeUntil(alarm),
                      style: TextStyle(
                        color: alarm.enabled
                            ? Colors.white.withValues(alpha: 0.55)
                            : Colors.white.withValues(alpha: 0.2),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tags
                    Wrap(
                      spacing: 6,
                      children: [
                        _tag(alarm.repeatLabel, alarm.enabled),
                        if (alarm.vibrate)
                          _tag('vibración', alarm.enabled,
                              icon: Icons.vibration),
                      ],
                    ),
                  ],
                ),
              ),
              // Botones
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (await _confirmDelete(alarm)) _delete(alarm);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Switch(
                    value: alarm.enabled,
                    onChanged: (v) => _toggle(alarm, v),
                    activeColor: const Color(0xFFFF9AD5),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, bool active, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFF9AD5).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 10,
                color: active
                    ? const Color(0xFFFF9AD5)
                    : Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                color: active
                    ? const Color(0xFFFF9AD5)
                    : Colors.white.withValues(alpha: 0.2),
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET DE CONFIGURACIÓN (nuevo + editar)
// ─────────────────────────────────────────────────────────────────────────────

class _AlarmConfigSheet extends StatefulWidget {
  final TimeOfDay time;
  final AlarmModel? existing; // null = nueva alarma

  const _AlarmConfigSheet({required this.time, this.existing});

  @override
  State<_AlarmConfigSheet> createState() => _AlarmConfigSheetState();
}

class _AlarmConfigSheetState extends State<_AlarmConfigSheet> {
  late AlarmRepeat _repeat;
  late List<bool> _days;
  late bool _vibrate;

  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _dayFull = [
    'Lunes', 'Martes', 'Miércoles',
    'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-llenar con valores existentes si es edición
    _repeat  = widget.existing?.repeat ?? AlarmRepeat.once;
    _days    = widget.existing != null
        ? List<bool>.from(widget.existing!.days)
        : [true, true, true, true, true, false, false];
    _vibrate = widget.existing?.vibrate ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.time.hour.toString().padLeft(2, '0');
    final m = widget.time.minute.toString().padLeft(2, '0');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Hora + etiqueta edición
          Center(
            child: Column(
              children: [
                Text('$h:$m',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 4)),
                if (widget.existing != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9AD5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Editando alarma',
                        style: TextStyle(
                            color: Color(0xFFFF9AD5), fontSize: 12)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Repetir
          const Text('Repetir',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip('Una vez', AlarmRepeat.once),
              const SizedBox(width: 8),
              _chip('Diario', AlarmRepeat.daily),
              const SizedBox(width: 8),
              _chip('Días', AlarmRepeat.custom),
            ],
          ),

          // Días (solo si custom)
          if (_repeat == AlarmRepeat.custom) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final active = _days[i];
                return Tooltip(
                  message: _dayFull[i],
                  child: GestureDetector(
                    onTap: () => setState(() => _days[i] = !_days[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFF9AD5)
                            : Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? const Color(0xFFFF9AD5)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Center(
                        child: Text(_dayLabels[i],
                            style: TextStyle(
                                color: active ? Colors.black : Colors.white60,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 20),

          // Vibrar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.vibration,
                    color: Colors.white54, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Vibrar',
                        style: TextStyle(
                            color: Colors.white, fontSize: 15))),
                Switch(
                  value: _vibrate,
                  onChanged: (v) => setState(() => _vibrate = v),
                  activeColor: const Color(0xFFFF9AD5),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9AD5),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    widget.existing != null
                        ? 'Actualizar'
                        : 'Guardar',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_repeat == AlarmRepeat.custom && !_days.any((d) => d)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día'),
          backgroundColor: Color(0xFF1A1A2E),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      AlarmModel(
        id: widget.existing?.id ?? AlarmService.generateId(),
        hour: widget.time.hour,
        minute: widget.time.minute,
        repeat: _repeat,
        days: List<bool>.from(_days),
        vibrate: _vibrate,
      ),
    );
  }

  Widget _chip(String label, AlarmRepeat value) {
    final selected = _repeat == value;
    return GestureDetector(
      onTap: () => setState(() => _repeat = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF9AD5)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF9AD5)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal)),
      ),
    );
  }
}
