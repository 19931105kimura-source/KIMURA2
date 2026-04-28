import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/high_value_order_effect_state.dart';

class OwnerHighValueEffectSettingsPage extends StatefulWidget {
  const OwnerHighValueEffectSettingsPage({super.key});

  @override
  State<OwnerHighValueEffectSettingsPage> createState() =>
      _OwnerHighValueEffectSettingsPageState();
}

class _OwnerHighValueEffectSettingsPageState
    extends State<OwnerHighValueEffectSettingsPage> {
  final _thresholdCtrl = TextEditingController();
  final _animationPathCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final s = context.read<HighValueOrderEffectState>();
    _thresholdCtrl.text = s.threshold.toString();
    _animationPathCtrl.text = s.animationPath;
    _initialized = true;
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    _animationPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    if (threshold == null || threshold < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('演出金額は1以上の数値で入力してください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<HighValueOrderEffectState>().save(
        threshold: threshold,
        animationPath: _animationPathCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('高額注文演出の設定を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('高額注文演出の設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'カート注文成功時に演出を出す条件と動画パスを設定します。',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '演出金額（円）',
              border: OutlineInputBorder(),
              hintText: '100000',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _animationPathCtrl,
            decoration: const InputDecoration(
              labelText: '演出動画パス',
              border: OutlineInputBorder(),
              hintText: '/uploads/promos/your_animation.mp4',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '※ 例: /uploads/promos/promo_xxx.mp4',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中...' : '保存'),
          ),
        ],
      ),
    );
  }
}