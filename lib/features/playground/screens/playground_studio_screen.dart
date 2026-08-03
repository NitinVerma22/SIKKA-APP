import 'dart:async';
import 'dart:math' as Math;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sikkaplay/core/config/app_config.dart';
import 'package:sikkaplay/features/games/shared/utils/game_notifications.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';
import 'package:sikkaplay/features/playground/screens/playground_profile_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String id;
  String? reaction;
  String? replyToText;
  bool isSeen;
  final bool isSystem;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.id,
    this.reaction,
    this.replyToText,
    this.isSeen = false,
    this.isSystem = false,
  });
}

class PlaygroundStudioScreen extends StatefulWidget {
  final dynamic partner;
  static String? activeChannelName;
  static String currentUserId = '';

  const PlaygroundStudioScreen({super.key, required this.partner});

  @override
  State<PlaygroundStudioScreen> createState() => _PlaygroundStudioScreenState();
}

class _PlaygroundStudioScreenState extends State<PlaygroundStudioScreen> {
  final PlaygroundService _service = PlaygroundService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  ChatMessage? _replyingToMessage;

  Timer? _heartbeatTimer;
  Timer? _gameRequestTimeoutTimer;
  IO.Socket? _chatSocket;

  String? _activeGiftEmoji;
  bool _partnerOnline = false;
  String _myUserId = '';
  String _privateChannelName = '';
  bool _partnerIsTyping = false;
  bool _isBlocked = false;
  bool _isBlockedByMe = false;
  bool _isBlockedByPartner = false;

  int _selectedWallpaperIndex = 0;
  List<String> _tttBoard = List.filled(9, '');
  bool _isMyTurn = false;
  String _mySymbol = 'X';
  String _partnerSymbol = 'O';
  bool _gameActive = false;
  StateSetter? _dialogStateSetter;
  bool _isMeTyping = false;
  Timer? _typingTimer;
  BuildContext? _gameWaitingDialogContext;
  BuildContext? _playAgainWaitingContext;
  BuildContext? _tttDialogContext;
  bool _gameOverSheetOpen = false;
  BuildContext? _gameOverSheetContext;
  bool _partnerHasLeft = false;
  String _partnerLeftMessage = '';

  bool get _isMatchmakingChat => (widget.partner['channelName']?.toString().startsWith('room-') == true) || (widget.partner['isMatchmaking'] == true);

  void _onTextChanged(String text) {
    if (!_isMeTyping) {
      setState(() {
        _isMeTyping = true;
      });
      _sendTypingStatus(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isMeTyping) {
        setState(() {
          _isMeTyping = false;
        });
        _sendTypingStatus(false);
      }
    });
  }

  Future<void> _sendTypingStatus(bool typing) async {
    if (_isBlocked) return;
    final channelName = widget.partner['channelName'] ?? '';
    final partnerId = widget.partner['partnerId'];
    await _service.setTypingStatus(channelName, typing, recipientId: partnerId);
  }

  Future<void> _sendPlaygroundSignal(String signalText) async {
    final channelName = widget.partner['channelName'] ?? '';
    
    if (_chatSocket?.connected == true) {
      final channelToEmmit = _privateChannelName.isNotEmpty ? _privateChannelName : channelName;
      _chatSocket?.emit('game_signal', {
        'channelName': channelToEmmit,
        'signal': signalText,
        'senderId': _myUserId,
      });
    }
  }

  void _requestTTTGame() {
    if (!_partnerOnline) {
      GameNotifications.showCoinUpdate(context, 'User is not available in chat');
      return;
    }
    if (_gameWaitingDialogContext != null || _tttDialogContext != null) {
      return;
    }
    _sendPlaygroundSignal('__GAME_REQUEST__');

    _gameRequestTimeoutTimer?.cancel();
    _gameRequestTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (_gameWaitingDialogContext != null && mounted) {
        _sendPlaygroundSignal('__GAME_REJECTED__');
        Navigator.pop(_gameWaitingDialogContext!);
        _gameWaitingDialogContext = null;
        GameNotifications.showCoinUpdate(context, 'Game request timed out');
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _gameWaitingDialogContext = dialogCtx;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF7B2CBF)),
              const SizedBox(height: 20),
              Text(
                'Game Invitation Sent',
                style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for partner to accept...',
                style: GoogleFonts.outfit(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _gameRequestTimeoutTimer?.cancel();
                _sendPlaygroundSignal('__GAME_REJECTED__');
                Navigator.pop(dialogCtx);
                _gameWaitingDialogContext = null;
              },
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) {
      _gameRequestTimeoutTimer?.cancel();
    });
  }

  void _showIncomingGameRequestDialog() {
    final partnerName = widget.partner['partnerName'] ?? 'SikkaPlay User';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              'Tic-Tac-Toe Request 🎮',
              style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          content: Text(
            '$partnerName wants to play Tic-Tac-Toe with you.',
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _sendPlaygroundSignal('__GAME_REJECTED__');
              },
              child: Text('DENY', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2CBF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _sendPlaygroundSignal('__GAME_ACCEPTED__');
                _startTTTGame(isInitiator: false);
              },
              child: Text('ACCEPT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _startTTTGame({required bool isInitiator}) {
    setState(() {
      _tttBoard = List.filled(9, '');
      _mySymbol = isInitiator ? 'X' : 'O';
      _partnerSymbol = isInitiator ? 'O' : 'X';
      _isMyTurn = isInitiator;
      _gameActive = true;
    });
    if (_tttDialogContext != null) {
      Navigator.pop(_tttDialogContext!);
      _tttDialogContext = null;
    }
    _showTicTacToeDialog();
  }

  void _handleTTTMoveSignal(String signal) {
    final parts = signal.split(':');
    if (parts.length >= 2) {
      final idx = int.tryParse(parts[1]);
      if (idx != null && idx >= 0 && idx < 9) {
        setState(() {
          _tttBoard[idx] = _partnerSymbol;
          _isMyTurn = true;
        });
        _dialogStateSetter?.call(() {});
        _checkTTTWinOrDraw();
      }
    }
  }

  void _playTTTMove(int index) {
    if (!_gameActive || !_isMyTurn || _tttBoard[index].isNotEmpty) return;
    setState(() {
      _tttBoard[index] = _mySymbol;
      _isMyTurn = false;
    });
    _dialogStateSetter?.call(() {});
    
    if (_chatSocket?.connected == true) {
      final channelName = widget.partner['channelName'] ?? '';
      final channelToEmmit = _privateChannelName.isNotEmpty ? _privateChannelName : channelName;
      _chatSocket?.emit('game_move', {
        'channelName': channelToEmmit,
        'index': index,
        'senderId': _myUserId,
      });
    }

    _sendPlaygroundSignal('__GAME_MOVE__:$index');
    _checkTTTWinOrDraw();
  }

  void _requestPlayAgain() {
    _sendPlaygroundSignal('__GAME_PLAY_AGAIN_REQUEST__');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _playAgainWaitingContext = dialogCtx;
        
        // 8-second timeout
        Timer(const Duration(seconds: 8), () {
          if (_playAgainWaitingContext == dialogCtx && mounted) {
            Navigator.pop(_playAgainWaitingContext!);
            _playAgainWaitingContext = null;
            _sendPlaygroundSignal('__GAME_PLAY_AGAIN_REJECTED__');
            GameNotifications.showCoinUpdate(context, 'User not accepting');
          }
        });

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF7B2CBF)),
              const SizedBox(height: 20),
              Text(
                'Play Again Request',
                style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for opponent response...',
                style: GoogleFonts.outfit(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _sendPlaygroundSignal('__GAME_PLAY_AGAIN_REJECTED__');
                Navigator.pop(dialogCtx);
                _playAgainWaitingContext = null;
              },
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPlayAgainRequestDialog() {
    final partnerName = widget.partner['partnerName'] ?? 'SikkaPlay User';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              'Play Again 🎮',
              style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          content: Text(
            '$partnerName wants to play again. Do you accept?',
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _sendPlaygroundSignal('__GAME_PLAY_AGAIN_REJECTED__');
              },
              child: Text('NO', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2CBF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _dismissGameOverSheet();
                _sendPlaygroundSignal('__GAME_PLAY_AGAIN_ACCEPTED__');
                _resetTTTGame();
              },
              child: Text('YES', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _resetTTTGame() {
    setState(() {
      final temp = _mySymbol;
      _mySymbol = _partnerSymbol;
      _partnerSymbol = temp;
      
      _tttBoard = List.filled(9, '');
      _isMyTurn = (_mySymbol == 'X');
      _gameActive = true;
    });
    if (_tttDialogContext == null) {
      _showTicTacToeDialog();
    } else {
      _dialogStateSetter?.call(() {});
    }
  }

  void _handleForfeit() {
    if (_gameWaitingDialogContext != null) {
      Navigator.pop(_gameWaitingDialogContext!);
      _gameWaitingDialogContext = null;
    }
    if (_playAgainWaitingContext != null) {
      Navigator.pop(_playAgainWaitingContext!);
      _playAgainWaitingContext = null;
    }
    if (_tttDialogContext != null) {
      Navigator.pop(_tttDialogContext!);
      _tttDialogContext = null;
    }
    _dialogStateSetter = null;
    if (_gameActive) {
      setState(() {
        _gameActive = false;
      });
      GameNotifications.showCoinUpdate(context, 'Opponent left. Game forfeited!');
    }
  }

  Future<bool?> _showQuitGameConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Quit Game? 🎮',
            style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Leaving the chat will forfeit the active game. Are you sure you want to quit?',
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2CBF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text('QUIT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showLeaveChatConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Leave Chat? 💬',
            style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Are you sure you want to exit this matchmaking chat?',
            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text('LEAVE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _checkTTTWinOrDraw() {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    final myName = 'You';
    final partnerName = widget.partner['partnerName'] ?? 'Opponent';

    for (final line in wins) {
      final a = _tttBoard[line[0]];
      final b = _tttBoard[line[1]];
      final c = _tttBoard[line[2]];
      if (a.isNotEmpty && a == b && a == c) {
        setState(() {
          _gameActive = false;
        });
        _dialogStateSetter?.call(() {});
        if (_tttDialogContext != null) {
          Navigator.pop(_tttDialogContext!);
          _tttDialogContext = null;
        }
        final isMeWinner = (a == _mySymbol);
        final winnerName = isMeWinner ? myName : partnerName;
        final loserName = isMeWinner ? partnerName : myName;
        _showGameOverCard(winnerName, loserName, isDraw: false);
        return;
      }
    }

    if (!_tttBoard.contains('')) {
      setState(() {
        _gameActive = false;
      });
      _dialogStateSetter?.call(() {});
      if (_tttDialogContext != null) {
        Navigator.pop(_tttDialogContext!);
        _tttDialogContext = null;
      }
      _showGameOverCard(myName, partnerName, isDraw: true);
    }
  }

  void _dismissGameOverSheet() {
    if (_gameOverSheetOpen && _gameOverSheetContext != null) {
      try {
        Navigator.pop(_gameOverSheetContext!);
      } catch (_) {}
      _gameOverSheetOpen = false;
      _gameOverSheetContext = null;
    }
  }

  void _showGameOverCard(String winnerName, String loserName, {required bool isDraw}) {
    _gameOverSheetOpen = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) {
        _gameOverSheetContext = ctx;
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(context).padding.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎆 CONGRATULATIONS! 🎉',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7B2CBF),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '✨ Game Over! Crackers Cracking ✨',
                style: GoogleFonts.outfit(
                  color: Colors.black38,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              if (isDraw) ...[
                Text(
                  'It\'s a Draw! 🤝',
                  style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text('$winnerName & $loserName', style: const TextStyle(color: Colors.black54, fontSize: 15)),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      winnerName.toUpperCase(),
                      style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text(
                      'WINNER 🏆',
                      style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loserName.toUpperCase(),
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Text(
                      'LOSS 💔',
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF7B2CBF),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF7B2CBF).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _gameOverSheetOpen = false;
                    _gameOverSheetContext = null;
                    _requestPlayAgain();
                  },
                  icon: const Icon(Icons.replay_rounded, size: 24),
                  label: Text('PLAY AGAIN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ).then((_) {
      _gameOverSheetOpen = false;
      _gameOverSheetContext = null;
    });

    Timer(const Duration(seconds: 5), () {
      if (mounted && _gameOverSheetOpen && _gameOverSheetContext != null) {
        try {
          Navigator.pop(_gameOverSheetContext!);
        } catch (_) {}
        _gameOverSheetOpen = false;
        _gameOverSheetContext = null;
      }
    });
  }

  void _showTicTacToeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _tttDialogContext = dialogCtx;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _dialogStateSetter = setDialogState;
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tic-Tac-Toe 🎮',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF3C096C),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black38),
                    onPressed: () async {
                      final shouldQuit = await _showQuitGameConfirmationDialog();
                      if (shouldQuit == true) {
                        _sendPlaygroundSignal('__GAME_FORFEITED__');
                        setState(() {
                          _gameActive = false;
                        });
                        _dialogStateSetter = null;
                        if (mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      }
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'You: $_mySymbol',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7B2CBF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _gameActive
                            ? (_isMyTurn ? 'Your Turn!' : 'Waiting...')
                            : 'Game Finished',
                        style: GoogleFonts.outfit(
                          color: _gameActive && _isMyTurn ? Colors.green : Colors.black45,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 9,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final cell = _tttBoard[index];
                        return InkWell(
                          onTap: () => _playTTTMove(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cell.isEmpty
                                    ? Colors.black.withOpacity(0.04)
                                    : const Color(0xFF7B2CBF),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cell,
                                style: GoogleFonts.outfit(
                                  color: cell == 'X' ? const Color(0xFF7B2CBF) : const Color(0xFFFF9E00),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!_gameActive) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B2CBF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_tttDialogContext != null) {
                          Navigator.pop(_tttDialogContext!);
                          _tttDialogContext = null;
                        }
                        _requestPlayAgain();
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('PLAY AGAIN'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _dialogStateSetter = null;
      _tttDialogContext = null;
    });
  }

  Widget _buildWallpaperBackground() {
    switch (_selectedWallpaperIndex) {
      case 1:
        // Pure Midnight (Dark Mode)
        return Container(color: const Color(0xFF121212));
      case 2:
        // Love Struck (Pinkish Hearts)
        return Container(
          color: const Color(0xFFFFF1F2),
          child: CustomPaint(
            painter: HeartsPainter(),
            child: Container(color: Colors.transparent),
          ),
        );
      case 3:
        // Sunset Romance (Warm Gradient)
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      case 4:
        // Match Aura (Blur Effect)
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFFAFBFD)),
            if (widget.partner['partnerAvatar'] != null && widget.partner['partnerAvatar'].toString().isNotEmpty)
              (widget.partner['partnerAvatar'].toString().startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: widget.partner['partnerAvatar'],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: const Color(0xFFE5E7EB)),
                    )
                  : Image.asset(
                      widget.partner['partnerAvatar'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => Container(color: const Color(0xFFE5E7EB)),
                    ))
            else
              CachedNetworkImage(
                imageUrl: 'https://picsum.photos/seed/${widget.partner['partnerId'] ?? "avatar"}/300',
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: const Color(0xFFE5E7EB)),
              ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.white.withOpacity(0.45)),
              ),
            ),
          ],
        );
      case 5:
        // Coffee Date (Warm Beige)
        return Container(color: const Color(0xFFF5EBE6));
      case 6:
        // Neon Cyberpunk (Gen-Z Vibe)
        return Container(
          color: const Color(0xFF0F0C1B),
          child: CustomPaint(
            painter: CyberpunkGridPainter(),
            child: Container(color: Colors.transparent),
          ),
        );
      case 7:
        // Anti-Gravity / Cosmic Dream
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF130E26), Color(0xFF1D1C3F), Color(0xFF2D1C3F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: CosmicDreamPainter(),
            child: Container(color: Colors.transparent),
          ),
        );
      case 0:
      default:
        // Classic Clean (Default)
        return Container(color: const Color(0xFFFAFBFD));
    }
  }

  BoxDecoration _getMessageBubbleDecoration(bool isMe) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    switch (_selectedWallpaperIndex) {
      case 1: // Pure Midnight
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)])
              : null,
          color: isMe ? null : const Color(0xFF1E1B2E),
          border: isMe ? null : Border.all(color: Colors.white12),
        );
      case 2: // Love Struck
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFFFF758F), Color(0xFFFF8FA3)])
              : null,
          color: isMe ? null : Colors.white,
          border: isMe ? null : Border.all(color: const Color(0xFFFFC6FF).withOpacity(0.5)),
        );
      case 3: // Sunset Romance
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFFFF5E62), Color(0xFFFF9966)])
              : null,
          color: isMe ? null : Colors.white.withOpacity(0.85),
          border: isMe ? null : Border.all(color: const Color(0xFFFFB7B2).withOpacity(0.3)),
        );
      case 4: // Match Aura
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)])
              : null,
          color: isMe ? null : Colors.white.withOpacity(0.85),
          border: isMe ? null : Border.all(color: Colors.black.withOpacity(0.06)),
        );
      case 5: // Coffee Date
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF8B5A2B), Color(0xFFA0522D)])
              : null,
          color: isMe ? null : Colors.white,
          border: isMe ? null : Border.all(color: const Color(0xFFD2B48C).withOpacity(0.4)),
        );
      case 6: // Neon Cyberpunk
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)])
              : null,
          color: isMe ? null : const Color(0xFF131127),
          border: isMe ? null : Border.all(color: const Color(0xFF7B2CBF), width: 1.5),
        );
      case 7: // Anti-Gravity
        return BoxDecoration(
          borderRadius: radius,
          color: isMe
              ? const Color(0xFF7B2CBF).withOpacity(0.45)
              : Colors.white.withOpacity(0.12),
          border: Border.all(
            color: isMe ? Colors.white30 : Colors.white24,
            width: 1.0,
          ),
        );
      case 0:
      default:
        return BoxDecoration(
          borderRadius: radius,
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)])
              : null,
          color: isMe ? null : Colors.white,
          border: isMe ? null : Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        );
    }
  }

  Color _getMessageTextColor(bool isMe) {
    if (isMe) {
      if (_selectedWallpaperIndex == 6) {
        return Colors.black; // Neon Cyberpunk high contrast text
      }
      return Colors.white;
    } else {
      switch (_selectedWallpaperIndex) {
        case 1: // Pure Midnight
          return Colors.white;
        case 5: // Coffee Date
          return const Color(0xFF4A3B32);
        case 6: // Neon Cyberpunk
          return const Color(0xFFE0AAFF);
        case 7: // Anti-Gravity
          return Colors.white;
        default:
          return const Color(0xFF3C096C);
      }
    }
  }

  Color _getMessageTimeColor(bool isMe) {
    if (isMe) {
      if (_selectedWallpaperIndex == 6) {
        return Colors.black54;
      }
      return Colors.white60;
    } else {
      switch (_selectedWallpaperIndex) {
        case 1: // Pure Midnight
          return Colors.white54;
        case 6: // Neon Cyberpunk
          return Colors.white54;
        case 7: // Anti-Gravity
          return Colors.white60;
        default:
          return Colors.black45;
      }
    }
  }

  void _loadSavedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt('chat_wallpaper_${widget.partner['partnerId']}');
    if (cached != null && mounted) {
      setState(() {
        _selectedWallpaperIndex = cached;
      });
    }
  }

  String _capitalizeName(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    return name.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _formatTime(DateTime time) {
    final int h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final String ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '${h}:${time.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  void initState() {
    super.initState();
    PlaygroundStudioScreen.activeChannelName = widget.partner['channelName'] ?? '';
    _loadSavedWallpaper();
    _loadChatHistory().then((_) {
      if (mounted) {
        _initChatSocket();
      }
    });
    _startHeartbeat();
  }

  Future<void> _loadChatHistory() async {
    final channelName = widget.partner['channelName'] ?? '';
    final partnerId = widget.partner['partnerId'] ?? '';
    final res = await _service.syncPlaygroundMessages(channelName, recipientId: partnerId, history: true);
    if (!mounted || res['success'] != true) return;

    final list = res['messages'] as List? ?? [];
    final isOnline = res['partnerOnline'] == true;
    final outgoingList = res['outgoingStatus'] as List? ?? [];
    final String myId = res['currentUserId'] ?? '';
    final bool isBlockedByMe = res['isBlockedByMe'] == true;
    final bool isBlockedByPartner = res['isBlockedByPartner'] == true;
    _isBlockedByMe = isBlockedByMe;
    _isBlockedByPartner = isBlockedByPartner;
    _isBlocked = isBlockedByMe || isBlockedByPartner;
    PlaygroundStudioScreen.currentUserId = myId;

    setState(() {
      _myUserId = myId;
      if (_myUserId.isNotEmpty && partnerId.isNotEmpty && (channelName.startsWith('friend-') || channelName.startsWith('private-'))) {
        final ids = [_myUserId, partnerId]..sort();
        _privateChannelName = 'private-chat-${ids[0]}-${ids[1]}';
      } else {
        _privateChannelName = channelName; // fallback to original channel name for matchmaking rooms
      }
      
      // Ensure socket joins the correct rooms now that we have the real IDs
      if (_chatSocket?.connected == true) {
        _chatSocket?.emit('join_room', _privateChannelName);
        if (_myUserId.isNotEmpty) {
          _chatSocket?.emit('join_room', 'friend-chat-$_myUserId');
        }
      }

      _partnerOnline = isOnline;
      
      // Smart merge to prevent UI flicker on reconnects
      final Set<String> existingIds = _messages.map((m) => m.id).toSet();
      final List<ChatMessage> newMessages = [];
      
      for (final rawMsg in list) {
        final String text = rawMsg['text'] ?? '';
        final String msgId = rawMsg['id'] ?? '';
        final String msgSenderId = rawMsg['senderId'] ?? '';
        final bool isMeMsg = msgSenderId != partnerId;
        final bool isSeenMsg = rawMsg['isSeen'] == true;

        // Skip call signaling messages in history display
        if (text.startsWith('__')) continue;

        // Check if reply message
        String cleanText = text;
        String? replyText;
        if (text.startsWith('[Reply to: "')) {
          final endQuoteIdx = text.indexOf('"]\n');
          if (endQuoteIdx != -1) {
            replyText = text.substring(12, endQuoteIdx);
            cleanText = text.substring(endQuoteIdx + 3);
          }
        }

        bool isDuplicateLocal = false;
        if (isMeMsg && !existingIds.contains(msgId)) {
          // Find a local message (not a UUID) with the exact same text
          final localIdx = _messages.indexWhere((m) => m.isMe && m.text == cleanText && m.id.length != 36);
          if (localIdx != -1) {
            _messages[localIdx] = ChatMessage(
              id: msgId,
              text: cleanText,
              isMe: true,
              timestamp: _messages[localIdx].timestamp,
              replyToText: _messages[localIdx].replyToText,
              isSeen: isSeenMsg,
              reaction: rawMsg['reaction'] ?? _messages[localIdx].reaction,
            );
            existingIds.add(msgId);
            isDuplicateLocal = true;
          }
        }

        if (isDuplicateLocal) continue;

        if (!existingIds.contains(msgId)) {
          newMessages.add(ChatMessage(
            id: msgId,
            text: cleanText,
            isMe: isMeMsg,
            timestamp: DateTime.tryParse(rawMsg['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
            replyToText: replyText,
            isSeen: isSeenMsg,
            reaction: rawMsg['reaction'],
          ));
        } else {
          // Update seen status or reaction for existing message
          final idx = _messages.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            _messages[idx].isSeen = isSeenMsg;
            _messages[idx].reaction = rawMsg['reaction'];
          }
        }
      }
      
      if (newMessages.isNotEmpty) {
        _messages.addAll(newMessages);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      // Sync outgoing seen status
      for (final out in outgoingList) {
        final String outId = out['id'] ?? '';
        final bool isSeenVal = out['isSeen'] == true;
        final idx = _messages.indexWhere((m) => m.id == outId && m.isMe);
        if (idx != -1) {
          _messages[idx].isSeen = isSeenVal;
        }
      }
    });

    _scrollToBottom();
  }

  @override
  void dispose() {
    if (_myUserId.isNotEmpty && _chatSocket?.connected == true) {
      _chatSocket?.emit('matchmaking_leave_chat', {
        'userId': _myUserId,
        'roomId': _privateChannelName,
        'userName': widget.partner['myUserName'] ?? 'Partner'
      });
      _chatSocket?.emit('chat_user_left', {
        'roomId': _privateChannelName,
        'userId': _myUserId,
        'userName': widget.partner['myUserName'] ?? 'Partner'
      });
    }
    _chatSocket?.disconnect();
    _chatSocket?.dispose();
    PlaygroundStudioScreen.activeChannelName = null;
    _heartbeatTimer?.cancel();
    _typingTimer?.cancel();
    _gameRequestTimeoutTimer?.cancel();
    if (_gameActive) {
      _sendPlaygroundSignal('__GAME_FORFEITED__');
    }
    if (_isMeTyping) {
      _sendTypingStatus(false);
    }
    _service.updateActiveChannel(null); // Clear active channel on exit
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startHeartbeat() {
    final channelName = widget.partner['channelName'] ?? '';
    final partnerId = widget.partner['partnerId'];
    _service.updateActiveChannel(channelName, recipientId: partnerId);
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _service.updateActiveChannel(channelName, recipientId: partnerId);
      }
    });
  }

  Future<void> _initChatSocket() async {
    final partnerName = widget.partner['partnerName'] ?? 'Partner';
    final originalChannelName = widget.partner['channelName'] ?? '';
    final channelToJoin = _privateChannelName.isNotEmpty ? _privateChannelName : originalChannelName;
    
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    final wsUrl = AuthService.baseUrl.replaceAll('/api/auth', '');
    
    _chatSocket = IO.io(wsUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableForceNew() // Crucial: creates a separate connection from the global socket!
      .disableAutoConnect()
      .setAuth({'token': token})
      .build());

    _chatSocket?.connect();

    _chatSocket?.onConnect((_) {
      final dynChannelToJoin = _privateChannelName.isNotEmpty ? _privateChannelName : originalChannelName;
      debugPrint('[Chat Socket] Connected to chat room: $dynChannelToJoin');
      _chatSocket?.emit('join_room', dynChannelToJoin);
      if (_myUserId.isNotEmpty) {
        // Fallback room
        _chatSocket?.emit('join_room', 'friend-chat-$_myUserId');
        // Let the partner know we rejoined the chat room
        _chatSocket?.emit('game_signal', {
          'channelName': dynChannelToJoin,
          'signal': '__CHAT_REJOINED__',
          'senderId': _myUserId,
        });
      }
      
      // Fetch history on connect/reconnect to catch any messages missed during micro-disconnects
      if (_myUserId.isNotEmpty) {
        _loadChatHistory();
      }
    });
    
    // Fallback if already connected
    if (_chatSocket?.connected ?? false) {
      final dynChannelToJoin = _privateChannelName.isNotEmpty ? _privateChannelName : originalChannelName;
      _chatSocket?.emit('join_room', dynChannelToJoin);
      if (_myUserId.isNotEmpty) {
        _chatSocket?.emit('join_room', 'friend-chat-$_myUserId');
        _chatSocket?.emit('game_signal', {
          'channelName': dynChannelToJoin,
          'signal': '__CHAT_REJOINED__',
          'senderId': _myUserId,
        });
      }
    }

    _chatSocket?.on('game_signal', (data) {
      if (!mounted) return;
      final String text = data['signal'] ?? '';
      final String msgSenderId = data['senderId'] ?? '';
      final partnerId = widget.partner['partnerId'] ?? '';
      
      if (msgSenderId == partnerId) {
        if (text == '__GAME_REQUEST__') {
          _showIncomingGameRequestDialog();
        } else if (text == '__GAME_ACCEPTED__') {
          _gameRequestTimeoutTimer?.cancel();
          if (_gameWaitingDialogContext != null) {
            Navigator.pop(_gameWaitingDialogContext!);
            _gameWaitingDialogContext = null;
          }
          _startTTTGame(isInitiator: true);
        } else if (text == '__GAME_REJECTED__') {
          _gameRequestTimeoutTimer?.cancel();
          if (_gameWaitingDialogContext != null) {
            Navigator.pop(_gameWaitingDialogContext!);
            _gameWaitingDialogContext = null;
          }
          GameNotifications.showCoinUpdate(context, 'Opponent denied to play');
        } else if (text == '__GAME_PLAY_AGAIN_REQUEST__') {
          _showPlayAgainRequestDialog();
        } else if (text == '__GAME_PLAY_AGAIN_ACCEPTED__') {
          if (_playAgainWaitingContext != null) {
            Navigator.pop(_playAgainWaitingContext!);
            _playAgainWaitingContext = null;
          }
          _dismissGameOverSheet();
          _resetTTTGame();
        } else if (text == '__CHAT_REJOINED__') {
          setState(() {
            _partnerHasLeft = false;
            _partnerLeftMessage = '';
          });
          _messages.add(ChatMessage(
            id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
            isMe: false,
            isSystem: true,
            text: '$partnerName joined the chat',
            timestamp: DateTime.now(),
          ));
          _scrollToBottom();
        } else if (text == '__GAME_PLAY_AGAIN_REJECTED__') {
          if (_playAgainWaitingContext != null) {
            Navigator.pop(_playAgainWaitingContext!);
            _playAgainWaitingContext = null;
          }
          if (_tttDialogContext != null) {
            Navigator.pop(_tttDialogContext!);
            _tttDialogContext = null;
          }
          _dialogStateSetter = null;
          GameNotifications.showCoinUpdate(context, 'Opponent denied to play again');
        } else if (text == '__GAME_FORFEITED__') {
          _handleForfeit();
        }
      }
    });

    _chatSocket?.on('game_move', (data) {
      if (!mounted) return;
      final String msgSenderId = data['senderId'] ?? '';
      final partnerId = widget.partner['partnerId'] ?? '';
      if (msgSenderId == partnerId) {
        final index = data['index'] as int?;
        if (index != null) {
          _handleTTTMoveSignal('__GAME_MOVE__:$index');
        }
      }
    });

    _chatSocket?.on('new_message', (rawMsg) {
      if (!mounted) return;
      
      final String text = rawMsg['text'] ?? '';
      final String msgId = rawMsg['id'] ?? '';
      final String msgSenderId = rawMsg['senderId'] ?? '';
      final partnerId = widget.partner['partnerId'] ?? '';
      final bool isMeMsg = (msgSenderId == _myUserId && _myUserId.isNotEmpty);
      if (msgSenderId == partnerId) {
        // Intercept signals
        if (text == '__GAME_REQUEST__') {
          _showIncomingGameRequestDialog();
          return;
        } else if (text == '__GAME_ACCEPTED__') {
          _gameRequestTimeoutTimer?.cancel();
          if (_gameWaitingDialogContext != null) {
            Navigator.pop(_gameWaitingDialogContext!);
            _gameWaitingDialogContext = null;
          }
          _startTTTGame(isInitiator: true);
          return;
        } else if (text == '__GAME_REJECTED__') {
          _gameRequestTimeoutTimer?.cancel();
          if (_gameWaitingDialogContext != null) {
            Navigator.pop(_gameWaitingDialogContext!);
            _gameWaitingDialogContext = null;
          }
          GameNotifications.showCoinUpdate(context, 'Opponent denied to play');
          return;
        } else if (text == '__GAME_PLAY_AGAIN_REQUEST__') {
          _showPlayAgainRequestDialog();
          return;
        } else if (text == '__GAME_PLAY_AGAIN_ACCEPTED__') {
          if (_playAgainWaitingContext != null) {
            Navigator.pop(_playAgainWaitingContext!);
            _playAgainWaitingContext = null;
          }
          _dismissGameOverSheet();
          _resetTTTGame();
          return;
        } else if (text == '__CHAT_REJOINED__') {
          setState(() {
            _partnerHasLeft = false;
            _partnerLeftMessage = '';
          });
          _messages.add(ChatMessage(
            id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
            isMe: false,
            isSystem: true,
            text: '$partnerName joined the chat',
            timestamp: DateTime.now(),
          ));
          _scrollToBottom();
          return;
        } else if (text == '__GAME_PLAY_AGAIN_REJECTED__') {
          if (_playAgainWaitingContext != null) {
            Navigator.pop(_playAgainWaitingContext!);
            _playAgainWaitingContext = null;
          }
          if (_tttDialogContext != null) {
            Navigator.pop(_tttDialogContext!);
            _tttDialogContext = null;
          }
          _dialogStateSetter = null;
          GameNotifications.showCoinUpdate(context, 'Opponent denied to play again');
          return;
        } else if (text == '__GAME_FORFEITED__') {
          _handleForfeit();
          return;
        } else if (text.startsWith('__GAME_MOVEUI__:') || text.startsWith('__GAME_MOVE__:')) {
          _handleTTTMoveSignal(text);
          return;
        } else if (text.startsWith('__REACT__:')) {
          _handleIncomingReactionSignal(text);
          return;
        }
      }

      if (text.startsWith('🎁 Sent a virtual gift:')) {
        final openParen = text.lastIndexOf('(');
        final closeParen = text.lastIndexOf(')');
        String emoji = '🎁';
        if (openParen != -1 && closeParen != -1 && closeParen > openParen) {
          emoji = text.substring(openParen + 1, closeParen);
        }
        setState(() {
          _activeGiftEmoji = emoji;
        });
      }

      String cleanText = text;
      String? replyText;
      if (text.startsWith('[Reply to: "')) {
        final endQuoteIdx = text.indexOf('"]\n');
        if (endQuoteIdx != -1) {
          replyText = text.substring(12, endQuoteIdx);
          cleanText = text.substring(endQuoteIdx + 3);
        }
      }

      if (isMeMsg) {
        // Find local pending message and update its ID
        final localIdx = _messages.indexWhere((m) => m.isMe && m.text == cleanText && m.id.length != 36);
        if (localIdx != -1) {
          setState(() {
            _messages[localIdx] = ChatMessage(
              id: msgId,
              text: cleanText,
              isMe: true,
              timestamp: _messages[localIdx].timestamp,
              replyToText: _messages[localIdx].replyToText,
              isSeen: rawMsg['isSeen'] == true,
              reaction: rawMsg['reaction'] ?? _messages[localIdx].reaction,
            );
          });
        }
        return;
      }

      // Emit mark_seen to the server so the sender gets the blue ticks instantly
      final dynChannel = _privateChannelName.isNotEmpty ? _privateChannelName : widget.partner['channelName'] ?? '';
      _chatSocket?.emit('mark_seen', {
        'channelName': dynChannel,
        'messageIds': [msgId]
      });

      if (_messages.any((m) => m.id == msgId)) return;

      setState(() {
        _messages.add(ChatMessage(
          id: msgId,
          text: cleanText,
          isMe: false,
          timestamp: DateTime.now(),
          replyToText: replyText,
          reaction: rawMsg['reaction'],
        ));
      });
      _scrollToBottom();
    });

    _chatSocket?.on('message_seen', (data) {
      if (!mounted) return;
      final List<dynamic> ids = data['messageIds'] ?? [];
      setState(() {
        for (final mId in ids) {
          final idx = _messages.indexWhere((m) => m.id == mId && m.isMe);
          if (idx != -1) {
            _messages[idx].isSeen = true;
          }
        }
      });
    });

    _chatSocket?.on('typing_status', (data) {
      if (!mounted) return;
      final partnerId = widget.partner['partnerId'];
      if (data['senderId'] == partnerId) {
        setState(() {
          _partnerIsTyping = data['isTyping'] == true;
        });
        if (_partnerIsTyping) _scrollToBottom();
      }
    });

    void handlePartnerLeft(dynamic data) {
      if (!mounted || _partnerHasLeft) return;
      final partnerName = widget.partner['partnerName'] ?? 'Partner';
      final msg = data != null && data['message'] != null ? data['message'].toString() : '$partnerName left this chat';
      setState(() {
        _partnerHasLeft = true;
        _partnerLeftMessage = msg;
        _partnerIsTyping = false;
        if (_gameActive) {
          _gameActive = false;
        }
      });
      _messages.add(ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        isMe: false,
        isSystem: true,
        text: msg,
        timestamp: DateTime.now(),
      ));
      _scrollToBottom();
    }

    _chatSocket?.on('partner_left', handlePartnerLeft);
    _chatSocket?.on('partner_left_chat', handlePartnerLeft);
  }

  void _handleIncomingReactionSignal(String signal) {
    // Format: __REACT__:messageId:emoji
    final parts = signal.split(':');
    if (parts.length >= 3) {
      final msgId = parts[1];
      final emoji = parts[2];
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          _messages[idx].reaction = emoji;
        }
      });
    }
  }

  void _addMessage(String text, bool isMe) {
    final messageId = '${DateTime.now().millisecondsSinceEpoch}-${text.hashCode}';
    setState(() {
      _messages.add(ChatMessage(
        id: messageId,
        text: text,
        isMe: isMe,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final channelName = widget.partner['channelName'] ?? '';
    final localMsgId = '${DateTime.now().millisecondsSinceEpoch}-${text.hashCode}';

    // Format if replying
    String payloadText = text;
    String? localReplyText;
    if (_replyingToMessage != null) {
      localReplyText = _replyingToMessage!.text;
      payloadText = '[Reply to: "${_replyingToMessage!.text}"]\n$text';
    }

    // Add locally immediately
    setState(() {
      _messages.add(ChatMessage(
        id: localMsgId,
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
        replyToText: localReplyText,
      ));
      _replyingToMessage = null; // Clear reply state
    });

    _scrollToBottom();
    _msgController.clear();

    // Send payload to DB buffer
    final partnerId = widget.partner['partnerId'] ?? '';
    final res = await _service.sendPlaygroundMessage(channelName, payloadText, recipientId: partnerId);

    if (res['success'] == true && res['message'] != null) {
      final serverMsg = res['message'];
      final String serverId = serverMsg['id'] ?? '';
      if (serverId.isNotEmpty) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == localMsgId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(
              id: serverId,
              text: _messages[idx].text,
              isMe: _messages[idx].isMe,
              timestamp: _messages[idx].timestamp,
              replyToText: _messages[idx].replyToText,
              isSeen: serverMsg['isSeen'] == true,
            );
          }
        });
      }
    }
  }

  // EMOJI REACTION SELECTION OVERLAY
  void _showEmojiReactionMenu(BuildContext context, ChatMessage msg, Offset offset) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss tap-outside target
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Reaction bar
          Positioned(
            left: offset.dx > MediaQuery.of(context).size.width - 200
                ? MediaQuery.of(context).size.width - 240
                : offset.dx,
            top: offset.dy - 56,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['❤️', '👍', '😂', '😮', '😢', '🙏'].map((emoji) {
                    return GestureDetector(
                      onTap: () async {
                        entry.remove();
                        setState(() {
                          msg.reaction = emoji;
                        });
                        // Sync reaction with peer via signaling message
                        final channelName = widget.partner['channelName'] ?? '';
                        final partnerId = widget.partner['partnerId'] ?? '';
                        await _service.sendPlaygroundMessage(channelName, '__REACT__:${msg.id}:$emoji', recipientId: partnerId);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(entry);
  }

  // VIRTUAL GIFTS SELECTION DRAWER
  void _showGiftsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1F0B3B), Color(0xFF130E26)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, -10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE0AAFF), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIRTUAL GIFTS',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Send gifts to show appreciation!',
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 8.0,
                    bottom: 24.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildGiftItem('Coffee', 50, '☕'),
                    _buildGiftItem('Heart', 50, '💖'),
                    _buildGiftItem('Ice Cream', 100, '🍦'),
                    _buildGiftItem('Bouquet', 100, '💐'),
                    _buildGiftItem('Rose', 200, '🌹'),
                    _buildGiftItem('Watch', 200, '⌚'),
                    _buildGiftItem('Chocolate', 500, '🍫'),
                    _buildGiftItem('Female Shoes', 500, '👠'),
                    _buildGiftItem('Boys Shoes', 500, '👞'),
                    _buildGiftItem('Crown', 1000, '👑'),
                    _buildGiftItem('Female Bag', 1000, '👜'),
                    _buildGiftItem('Ring', 2000, '💍'),
                    _buildGiftItem('Dress', 2000, '👗'),
                    _buildGiftItem('Coat Pant', 2000, '👔'),
                    _buildGiftItem('Jewelry', 2000, '💎'),
                    _buildGiftItem('Female Jackpot', 5000, '🛍️'),
                    _buildGiftItem('Boys Kit', 5000, '💼'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftItem(String name, int cost, String icon) {
    final partnerId = widget.partner['partnerId'] ?? '';
    final partnerName = widget.partner['partnerName'] ?? 'Player';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final giftRes = await _service.sendVirtualGift(partnerId, name);
          if (mounted) {
            Navigator.pop(context);
            if (giftRes['success'] == true) {
              setState(() {
                _activeGiftEmoji = icon;
              });
              final String giftText = '🎁 Sent a virtual gift: $name ($icon)';
              _addMessage(giftText, true);
              final channelName = widget.partner['channelName'] ?? '';
              await _service.sendPlaygroundMessage(channelName, giftText, recipientId: partnerId);
            } else {
              final errorStr = (giftRes['error'] ?? '').toString().toLowerCase();
              if (errorStr.contains('balance') || errorStr.contains('insufficient')) {
                _showInsufficientBalanceDialog();
              } else {
                _showLightAlert('Gift Failed', giftRes['error'] ?? 'Gift transfer failed');
              }
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_rounded, color: Color(0xFF00F5D4), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '$cost',
                    style: GoogleFonts.outfit(color: const Color(0xFF00F5D4), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CUSTOM LIGHT-THEME NOTIFICATION ALERTS
  void _showLightAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2CBF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            'INSUFFICIENT BALANCE',
            style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        content: Text(
          'You do not have enough coins to send this gift.\nGo to Wallet to add coins.',
          style: GoogleFonts.outfit(color: Colors.black87, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2CBF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.push('/wallet');
            },
            child: Text('ADD COINS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF130E26),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    final res = await _service.clearChatHistory(widget.partner['partnerId'] ?? '');
    if (res['success'] == true) {
      if (mounted) {
        setState(() {
          _messages.clear();
        });
        GameNotifications.showCoinUpdate(context, 'Chat history cleared');
      }
    } else {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to clear chat');
      }
    }
  }

  Future<void> _blockUser() async {
    final res = await _service.blockUser(widget.partner['partnerId'] ?? '');
    if (res['success'] == true) {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, 'User blocked successfully');
        _loadChatHistory();
      }
    } else {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to block user');
      }
    }
  }

  Future<void> _unblockUser() async {
    final res = await _service.unblockUser(widget.partner['partnerId'] ?? '');
    if (res['success'] == true) {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, 'User unblocked successfully');
        _loadChatHistory();
      }
    } else {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to unblock');
      }
    }
  }

  Future<void> _deleteChatAndUnfriend() async {
    await _clearChat();
    await _unfriendUser();
  }

  Future<void> _unfriendUser() async {
    final res = await _service.unfriendUser(widget.partner['partnerId'] ?? '');
    if (res['success'] == true) {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, 'User unfriended successfully');
        context.pop();
      }
    } else {
      if (mounted) {
        GameNotifications.showCoinUpdate(context, res['error'] ?? 'Failed to unfriend');
      }
    }
  }

  void _showReportDialog() {
    final List<String> reasons = [
      'Spam',
      'Harassment',
      'Fake Profile',
      'Nudity / Adult Content',
      'Hate Speech',
      'Scam / Fraud',
      'Violence',
      'Other',
    ];
    String selectedReason = reasons.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF130E26),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report User',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please select a reason for reporting this user:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: reasons.map((reason) {
                          return RadioListTile<String>(
                            title: Text(reason, style: const TextStyle(color: Colors.white)),
                            value: reason,
                            groupValue: selectedReason,
                            activeColor: const Color(0xFF9D4EDD),
                            onChanged: (String? value) {
                              if (value != null) {
                                setSheetState(() {
                                  selectedReason = value;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // Close bottom sheet
                        _showConfirmDialog(
                          'Confirm Report',
                          'Are you sure you want to report this user for \$selectedReason?',
                          () async {
                            final res = await _service.reportUser(widget.partner['partnerId'] ?? '', selectedReason);
                            if (mounted) {
                              if (res['success'] == true) {
                                GameNotifications.showCoinUpdate(context, 'Thank you. Your report has been submitted.');
                              } else {
                                GameNotifications.showCoinUpdate(context, res['error'] ?? 'Report failed');
                              }
                            }
                          },
                        );
                      },
                      child: const Text('SUBMIT REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleExit() async {
    if (_gameActive) {
      final shouldQuit = await _showQuitGameConfirmationDialog();
      if (shouldQuit == true && mounted) {
        _sendPlaygroundSignal('__GAME_FORFEITED__');
        setState(() {
          _gameActive = false;
        });
        if (mounted) Navigator.pop(context);
      }
    } else if (_isMatchmakingChat && !_partnerHasLeft) {
      final shouldLeave = await _showLeaveChatConfirmationDialog();
      if (shouldLeave == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.partner['partnerName'] ?? 'SikkaPlay Player';
    final partnerUsername = widget.partner['partnerUsername'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFAFBFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3C096C), size: 14),
              onPressed: () => _handleExit(),
            ),
          ),
        ),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final String target = (partnerUsername != null && partnerUsername.toString().trim().isNotEmpty)
                ? partnerUsername.toString()
                : (widget.partner['partnerId']?.toString() ?? '');
            
            if (target.isNotEmpty) {
              // Using Navigator.push instead of GoRouter's context.push because PlaygroundStudioScreen is pushed on rootNavigatorKey, 
              // which causes GoRouter to push the profile screen under this screen.
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaygroundProfileScreen(username: target),
                ),
              );
            }
          },
          child: Row(
            children: [
              Stack(
                children: [
                  if (_isBlockedByPartner)
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE9D5FF),
                      child: Icon(Icons.person, color: Color(0xFF7B2CBF), size: 20),
                    )
                  else if (widget.partner['partnerAvatar'] != null && widget.partner['partnerAvatar'].toString().isNotEmpty)
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE9D5FF),
                      backgroundImage: widget.partner['partnerAvatar'].toString().startsWith('http')
                          ? CachedNetworkImageProvider(widget.partner['partnerAvatar']) as ImageProvider
                          : AssetImage(widget.partner['partnerAvatar']),
                      onBackgroundImageError: (_, __) {},
                    )
                  else
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFE9D5FF),
                      child: Text(
                        _getInitials(partnerName),
                        style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (_partnerOnline && !_isBlockedByPartner)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF06D6A0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizeName(partnerName),
                      style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    if (_partnerIsTyping)
                      Text(
                        'typing...',
                        style: GoogleFonts.outfit(color: const Color(0xFF7B2CBF), fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    else if (partnerUsername != null)
                      Text(
                        '@$partnerUsername',
                        style: GoogleFonts.outfit(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Wallpaper Dropdown Menu
          PopupMenuButton<int>(
            icon: const Icon(Icons.wallpaper_rounded, color: Color(0xFF7B2CBF)),
            onSelected: (int index) async {
              setState(() {
                _selectedWallpaperIndex = index;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('chat_wallpaper_${widget.partner['partnerId']}', index);
              final names = [
                'Classic Clean',
                'Pure Midnight (Dark Mode)',
                'Love Struck (Pinkish Hearts)',
                'Sunset Romance (Warm Gradient)',
                'Match Aura (Blur Effect)',
                'Coffee Date (Warm Beige)',
                'Neon Cyberpunk (Gen-Z Vibe)',
                'Anti-Gravity / Cosmic Dream'
              ];
              GameNotifications.showCoinUpdate(context, 'Wallpaper: ${names[index]}');
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 0,
                child: Text('Classic Clean'),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Pure Midnight (Dark Mode)'),
              ),
              const PopupMenuItem<int>(
                value: 2,
                child: Text('Love Struck (Pinkish Hearts)'),
              ),
              const PopupMenuItem<int>(
                value: 3,
                child: Text('Sunset Romance (Warm Gradient)'),
              ),
              const PopupMenuItem<int>(
                value: 4,
                child: Text('Match Aura (Blur Effect)'),
              ),
              const PopupMenuItem<int>(
                value: 5,
                child: Text('Coffee Date (Warm Beige)'),
              ),
              const PopupMenuItem<int>(
                value: 6,
                child: Text('Neon Cyberpunk (Gen-Z Vibe)'),
              ),
              const PopupMenuItem<int>(
                value: 7,
                child: Text('Anti-Gravity / Cosmic Dream'),
              ),
            ],
          ),
          // Tic-Tac-Toe Game Launcher Button
          IconButton(
            icon: const Icon(Icons.sports_esports_rounded, color: Color(0xFF7B2CBF)),
            onPressed: _requestTTTGame,
          ),
          // Menu Options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF3C096C)),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_chat',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: Colors.black87, size: 20),
                    const SizedBox(width: 12),
                    Text('Clear Chat', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text('Block User', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.report_problem_rounded, color: Colors.black87, size: 20),
                    const SizedBox(width: 12),
                    Text('Report User', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'clear_chat') {
                _showConfirmDialog('Clear Chat', 'Are you sure you want to delete this conversation? This action cannot be undone.', _clearChat);
              } else if (value == 'block') {
                _showConfirmDialog('Block User', "Blocked users won't be able to message you, call you, or find your profile.", _blockUser);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildWallpaperBackground(),
          ),
          Column(
            children: [

          // Message Feed list
          Expanded(
            child: (_messages.isEmpty && !_partnerIsTyping)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Say hello to start chatting!',
                          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_partnerIsTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicatorBubble();
                      }
                      final msg = _messages[index];
                      if (msg.isSystem) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Center(
                            child: Text(
                              msg.text,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return GestureDetector(
                        onLongPressStart: (details) {
                          _showEmojiReactionMenu(context, msg, details.globalPosition);
                        },
                        child: Align(
                          alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Dismissible(
                            key: Key(msg.id),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (dir) async {
                              setState(() {
                                _replyingToMessage = msg;
                              });
                              return false; // Prevent actual swipe deletion
                            },
                            background: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Icon(Icons.reply_rounded, color: const Color(0xFFC77DFF).withValues(alpha: 0.8)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  decoration: _getMessageBubbleDecoration(msg.isMe),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Reply Block
                                      if (msg.replyToText != null) ...[
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: msg.isMe
                                                ? Colors.black12
                                                : (_selectedWallpaperIndex == 1 ||
                                                        _selectedWallpaperIndex == 6 ||
                                                        _selectedWallpaperIndex == 7
                                                    ? Colors.white10
                                                    : const Color(0xFFF3E8FF)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.reply_rounded,
                                                color: msg.isMe
                                                    ? const Color(0xFFE9D5FF)
                                                    : _getMessageTextColor(false),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  msg.replyToText!,
                                                  style: TextStyle(
                                                    color: msg.isMe
                                                        ? Colors.white70
                                                        : _getMessageTextColor(false).withOpacity(0.7),
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      Text(
                                        msg.text,
                                        style: GoogleFonts.outfit(
                                          color: _getMessageTextColor(msg.isMe),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTime(msg.timestamp),
                                            style: TextStyle(
                                              color: _getMessageTimeColor(msg.isMe),
                                              fontSize: 9,
                                            ),
                                          ),
                                          if (msg.isMe) ...[
                                            const SizedBox(width: 4),
                                            _buildTick(msg),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Reaction Badge
                                if (msg.reaction != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(msg.reaction!, style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input controls
          SafeArea(
            bottom: true,
            child: Container(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: _isBlockedByMe
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('You blocked this user', style: GoogleFonts.outfit(color: Colors.black54, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _showConfirmDialog('Unblock User', 'Are you sure you want to unblock this user?', _unblockUser),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B2CBF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Unblock', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                          OutlinedButton(
                            onPressed: () => _showConfirmDialog('Delete Chat', 'Are you sure you want to delete this chat?', _deleteChatAndUnfriend),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  )
                : _isBlockedByPartner
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Text('You were blocked by this user.', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                      ],
                    )
                  : _partnerHasLeft && _isMatchmakingChat
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.exit_to_app_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _partnerLeftMessage.isNotEmpty ? _partnerLeftMessage : '${widget.partner['partnerName'] ?? 'Partner'} left this chat',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replying preview banner
                if (_replyingToMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply_rounded, color: Color(0xFF7B2CBF), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Replying to: "${_replyingToMessage!.text}"',
                            style: GoogleFonts.outfit(color: const Color(0xFF3C096C), fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black38, size: 16),
                          onPressed: () {
                            setState(() {
                              _replyingToMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    // Gift trigger button
                    IconButton(
                      icon: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF7B2CBF), size: 26),
                      onPressed: _showGiftsDrawer,
                    ),
                    const SizedBox(width: 8),

                    // Text field input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _msgController,
                          style: const TextStyle(color: Color(0xFF3C096C)),
                          onChanged: _onTextChanged,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: Colors.black38),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Glowing Send Button
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ), // closes Column
          ), // closes Container
        ), // closes SafeArea
      ], // closes outer Column children
      ), // closes outer Column
      if (_activeGiftEmoji != null)
        Positioned.fill(
          child: Container(
            color: Colors.black45, // Dim background slightly
            child: _GiftPopupOverlay(
              emoji: _activeGiftEmoji!,
              onDismiss: () {
                setState(() {
                  _activeGiftEmoji = null;
                });
              },
            ),
          ),
        ),
    ],
  ),
),
);
  }

  Widget _buildTick(ChatMessage msg) {
    if (msg.isSeen) {
      return const Text(
        '✓✓',
        style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
      );
    } else if (_partnerOnline) {
      return Text(
        '✓✓',
        style: TextStyle(color: _getMessageTimeColor(true).withOpacity(0.5), fontSize: 11),
      );
    } else {
      return Text(
        '✓',
        style: TextStyle(color: _getMessageTimeColor(true).withOpacity(0.5), fontSize: 11),
      );
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'SP';
    final clean = name.trim();
    return clean.substring(0, 1).toUpperCase();
  }

  Widget _buildTypingIndicatorBubble() {
    final bubbleColor = _getMessageTextColor(false);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _getMessageBubbleDecoration(false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedTypingDots(dotColor: bubbleColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class AnimatedTypingDots extends StatefulWidget {
  final Color dotColor;
  const AnimatedTypingDots({super.key, required this.dotColor});

  @override
  State<AnimatedTypingDots> createState() => _AnimatedTypingDotsState();
}

class _AnimatedTypingDotsState extends State<AnimatedTypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final normalizedTime = (_controller.value - delay) % 1.0;
            final double bounce = normalizedTime < 0.5
                ? -6 * Math.sin(normalizedTime * Math.pi * 2)
                : 0.0;
            return Transform.translate(
              offset: Offset(0, bounce),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _GiftPopupOverlay extends StatefulWidget {
  final String emoji;
  final VoidCallback onDismiss;

  const _GiftPopupOverlay({required this.emoji, required this.onDismiss});

  @override
  State<_GiftPopupOverlay> createState() => _GiftPopupOverlayState();
}

class _GiftPopupOverlayState extends State<_GiftPopupOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Slow popup
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Elastic pop up effect
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white, // White background
              shape: BoxShape.circle, // Circular shape
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.85), // Green glowing glow
                  blurRadius: 45,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 68),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7B2CBF).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    
    const double step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB7B2).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    
    for (double x = 30; x < size.width; x += 60) {
      for (double y = 30; y < size.height; y += 60) {
        final path = Path();
        path.moveTo(x, y + 6);
        path.cubicTo(x - 6, y, x - 12, y + 6, x - 12, y + 14);
        path.cubicTo(x - 12, y + 22, x - 4, y + 28, x, y + 34);
        path.cubicTo(x + 4, y + 28, x + 12, y + 22, x + 12, y + 14);
        path.cubicTo(x + 12, y + 6, x + 6, y, x, y + 6);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CyberpunkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7B2CBF).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CosmicDreamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Soft Purple Orb Glow
    paint.shader = RadialGradient(
      colors: [const Color(0xFF7B2CBF).withValues(alpha: 0.2), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.25), radius: 160));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.25), 160, paint);

    // Soft Magenta Orb Glow
    paint.shader = RadialGradient(
      colors: [const Color(0xFFE040FB).withValues(alpha: 0.18), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.65), radius: 200));
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.65), 200, paint);

    // Soft Cyan Orb Glow
    paint.shader = RadialGradient(
      colors: [const Color(0xFF00E5FF).withValues(alpha: 0.15), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.45, size.height * 0.85), radius: 140));
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.85), 140, paint);

    // Subtle Glassmorphic stars
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.15), 3, starPaint);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.22), 4, starPaint);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.55), 2, starPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.48), 3.5, starPaint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.75), 2.5, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
