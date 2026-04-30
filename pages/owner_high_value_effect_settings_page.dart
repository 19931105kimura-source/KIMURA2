import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../data/server_config.dart';
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
  final _displayMsCtrl = TextEditingController();
  double _scale = 1.0;
  bool _initialized = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final s = context.read<HighValueOrderEffectState>();
    _thresholdCtrl.text = s.threshold.toString();
    _animationPathCtrl.text = s.animationPath;
    _displayMsCtrl.text = s.displayMs.toString();
    _scale = s.scale;
    _initialized = true;
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    _animationPathCtrl.dispose();
    _displayMsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    final displayMs = int.tryParse(_displayMsCtrl.text.trim());
    if (threshold == null || threshold < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('演出金額は1以上の数値で入力してください')),
      );
      return;
    }
    if (displayMs == null || displayMs < 1000 || displayMs > 15000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('表示時間は1000〜15000msで入力してください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<HighValueOrderEffectState>().save(
        threshold: threshold,
        animationPath: _animationPathCtrl.text,
        displayMs: displayMs,
        scale: _scale,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('高額注文演出の設定を保存しました')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
}

  Future<void> _pickAndUploadVideo() async {
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );
      if (result == null) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('動画データの読み込みに失敗しました')),
        );
        return;
      }

      final req = http.MultipartRequest(
        'POST',
        ServerConfig.api('/api/upload/promo'),
      );
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );

      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロード失敗: HTTP ${res.statusCode}')),
        );
        return;
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final path = decoded['url']?.toString();
      if (path == null || path.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アップロード結果のURL取得に失敗しました')),
        );
        return;
      }

      _animationPathCtrl.text = path.trim();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('動画をサーバーへ保存しました。続けて「保存」を押してください')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アップロードエラー: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
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
            controller: _displayMsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '表示時間（ms）',
              border: OutlineInputBorder(),
              hintText: '4200',
            ),
          ),
          const SizedBox(height: 16),
          Text('演出サイズ: ${(_scale * 100).round()}%'),
          Slider(
            value: _scale,
            min: 0.4,
            max: 1.0,
            divisions: 12,
            label: '${(_scale * 100).round()}%',
            onChanged: (v) => setState(() => _scale = v),
          ),
          const SizedBox(height: 8),
         TextField(
            controller: _animationPathCtrl,
            decoration: const InputDecoration(
              labelText: '演出動画パス',
              border: OutlineInputBorder(),
              hintText: '/uploads/promos/your_animation.mp4',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickAndUploadVideo,
            icon: const Icon(Icons.cloud_upload),
            label: Text(_uploading ? 'アップロード中...' : '動画を選んでサーバーにアップロード'),
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