import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:humm_error_handler/humm_error_handler.dart';

class HummCrashlogScreen extends StatefulWidget {
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? scaffoldBackgroundColor;
  final Duration snackBarDuration;

  const HummCrashlogScreen._({
    this.primaryColor,
    this.secondaryColor,
    this.scaffoldBackgroundColor,
    this.snackBarDuration = const Duration(seconds: 2),
  });

  @override
  State<HummCrashlogScreen> createState() => _HummCrashlogScreenState();

  static void show(
    BuildContext context, {
    Color? primaryColor,
    Color? secondaryColor,
    Color? scaffoldBackgroundColor,
    Duration snackBarDuration = const Duration(seconds: 2),
  }) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return HummCrashlogScreen._(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
          snackBarDuration: snackBarDuration,
        );
      },
    );
  }
}

class _HummCrashlogScreenState extends State<HummCrashlogScreen> {
  String crashlogTxt = '';
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final secondaryColor = widget.secondaryColor ?? theme.secondaryHeaderColor;
    final scaffoldBackgroundColor = widget.scaffoldBackgroundColor ?? theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Crashlogs'),
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : crashlogTxt.isEmpty
              ? Center(
                  child: Text(
                    'No logs available',
                    style: theme.textTheme.titleMedium,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: SelectableRegion(
                    focusNode: FocusNode(),
                    selectionControls:
                        Platform.isIOS ? CupertinoTextSelectionControls() : MaterialTextSelectionControls(),
                    child: Column(
                      children: [
                        Text(crashlogTxt),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                heroTag: 'clear',
                onPressed: _clearLogs,
                label: const Text('Clear logs'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                heroTag: 'copy',
                onPressed: _copyLogs,
                label: const Text('Copy logs'),
                backgroundColor: primaryColor,
                foregroundColor: secondaryColor,
              ),
            ),
          FloatingActionButton(
            heroTag: 'main',
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            backgroundColor: primaryColor,
            foregroundColor: secondaryColor,
            child: Icon(_isExpanded ? Icons.close : Icons.menu),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await HummErrorHandler().errorStorage.getErrorLog();
      setState(() {
        crashlogTxt = logs ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        crashlogTxt = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await HummErrorHandler().errorStorage.saveErrorLog('');
      setState(() {
        crashlogTxt = '';
        _isLoading = false;
      });

      if (mounted) {
        _showSnackBar('Logs cleared successfully');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showSnackBar('Failed to clear logs');
      }
    }
  }

  void _copyLogs() async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text: crashlogTxt,
        ),
      );

      if (mounted) {
        _showSnackBar('Logs copied to clipboard');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to copy logs');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        duration: widget.snackBarDuration,
        backgroundColor: widget.primaryColor ?? Theme.of(context).primaryColor,
      ),
    );
  }
}
