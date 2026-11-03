// Company build (Remote-AGC): a minimal home screen.
// Shows only the logo, the ID, a copy button and the connection status.
// A narrow side strip opens a panel where staff type an ID to connect.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:window_manager/window_manager.dart';

/// Use the minimal home screen instead of the full RustDesk one.
const bool kAgcSimpleUi = true;

/// Fixed size of the home screen (without the title bar).
const Size kAgcHomeSize = Size(560, 420);

const Color _kNavy = Color(0xFF0F1640);
const Color _kBlue = Color(0xFF0C6FB3);
const Color _kLightBlue = Color(0xFF47ADE2);
const Color _kMuted = Color(0xFF3A4466);
const Color _kStripBg = Color(0xFFF2F7FC);
const Color _kStripBorder = Color(0xFFDCE6F2);

Size getAgcWindowSize() {
  final magicWidth = isWindows ? 11.0 : 2.0;
  return kAgcHomeSize + Offset(magicWidth, kDesktopRemoteTabBarHeight + 10.0);
}

class AgcHomePage extends StatefulWidget {
  const AgcHomePage({Key? key}) : super(key: key);

  @override
  State<AgcHomePage> createState() => _AgcHomePageState();
}

class _AgcHomePageState extends State<AgcHomePage>
    with AutomaticKeepAliveClientMixin {
  final _peerIdController = TextEditingController();
  final _peerIdFocus = FocusNode();
  bool _panelOpen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await windowManager.setSize(getAgcWindowSize());
      setResizable(false);
    });
  }

  @override
  void dispose() {
    _peerIdController.dispose();
    _peerIdFocus.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    if (_panelOpen) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _peerIdFocus.requestFocus());
    }
  }

  void _connect() {
    final id = _peerIdController.text.replaceAll(RegExp(r'\s'), '');
    if (id.isEmpty) return;
    connect(context, id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // In RTL the first child is on the right: main content, then the panel,
    // then the side strip on the far left.
    return Container(
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildMain(context)),
          if (_panelOpen) _buildPanel(context),
          _buildStrip(context),
        ],
      ),
    );
  }

  Widget _buildMain(BuildContext context) {
    final model = gFFI.serverModel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          loadLogo(),
          const SizedBox(height: 14),
          Text(
            translate('agc_your_id'),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500, color: _kMuted),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: model.serverId,
            builder: (context, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SelectableText(
                value.text,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: _kNavy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: model.serverId.text.replaceAll(' ', '')));
              showToast(translate('Copied'));
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(translate('agc_copy_id')),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlue,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              side: const BorderSide(color: _kBlue, width: 2),
              shape: const StadiumBorder(),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            translate('agc_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: _kMuted),
          ),
          const Spacer(),
          // Ready / connecting / red error (no internet, HTTP code, ...).
          const OnlineStatusWidget(),
        ],
      ),
    );
  }

  Widget _buildStrip(BuildContext context) {
    return Material(
      color: _kStripBg,
      child: InkWell(
        onTap: _togglePanel,
        child: Container(
          width: 48,
          decoration: const BoxDecoration(
            border: BorderDirectional(
                start: BorderSide(color: _kStripBorder, width: 1)),
          ),
          child: Tooltip(
            message: translate('agc_connect_title'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _panelOpen
                      ? Icons.close_rounded
                      : Icons.desktop_windows_outlined,
                  color: _kBlue,
                  size: 22,
                ),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    translate('agc_connect_tab'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
                        letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Container(
      width: 260,
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translate('agc_connect_title'),
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            translate('agc_peer_id_label'),
            style: const TextStyle(fontSize: 15, color: Color(0xFFC9D6EE)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _peerIdController,
            focusNode: _peerIdFocus,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _connect(),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _kNavy),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: '123 456 789',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kLightBlue, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kLightBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _connect,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kLightBlue,
              foregroundColor: _kNavy,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            child: Text(translate('agc_connect_btn')),
          ),
          const SizedBox(height: 12),
          Text(
            translate('agc_connect_note'),
            style: const TextStyle(
                fontSize: 13, color: Color(0xFFC9D6EE), height: 1.5),
          ),
        ],
      ),
    );
  }
}
