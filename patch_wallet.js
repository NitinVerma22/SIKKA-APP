const fs = require('fs');

function updateWalletScreen() {
    const path = 'lib/features/wallet/screens/wallet_screen.dart';
    let content = fs.readFileSync(path, 'utf8');

    content = content.replace(
        'String name, String? optionId) onWithdraw;',
        'String name, String phone, String? optionId) onWithdraw;'
    );

    content = content.replace(
        'final String? initialName;\n',
        'final String? initialName;\n  final String? initialPhone;\n'
    );
    content = content.replace(
        'final String? initialName;\r\n',
        'final String? initialName;\r\n  final String? initialPhone;\r\n'
    );

    content = content.replace(
        'this.initialName,\n',
        'this.initialName,\n    this.initialPhone,\n'
    );
    content = content.replace(
        'this.initialName,\r\n',
        'this.initialName,\r\n    this.initialPhone,\r\n'
    );

    content = content.replace(
        'final _nameController = TextEditingController();\n',
        'final _nameController = TextEditingController();\n  final _phoneController = TextEditingController();\n'
    );
    content = content.replace(
        'final _nameController = TextEditingController();\r\n',
        'final _nameController = TextEditingController();\r\n  final _phoneController = TextEditingController();\r\n'
    );

    content = content.replace(
        '_nameController.text = widget.initialName ?? \'\';\n',
        '_nameController.text = widget.initialName ?? \'\';\n    _phoneController.text = widget.initialPhone ?? \'\';\n'
    );
    content = content.replace(
        '_nameController.text = widget.initialName ?? \'\';\r\n',
        '_nameController.text = widget.initialName ?? \'\';\r\n    _phoneController.text = widget.initialPhone ?? \'\';\r\n'
    );

    content = content.replace(
        '_nameController.dispose();\n',
        '_nameController.dispose();\n    _phoneController.dispose();\n'
    );
    content = content.replace(
        '_nameController.dispose();\r\n',
        '_nameController.dispose();\r\n    _phoneController.dispose();\r\n'
    );

    content = content.replace(
        'final tempNameController = TextEditingController(',
        'final tempPhoneController = TextEditingController(text: _phoneController.text);\n      final tempNameController = TextEditingController('
    );

    const newDialogFields = \              children: [
                TextField(
                  controller: tempPhoneController,
                  style: GoogleFonts.outfit(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                    hintText: 'Enter your phone number',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tempNameController,\;
                  
    content = content.replace(
        \              children: [\\r\\n                TextField(\\r\\n                  controller: tempNameController,\,
        newDialogFields
    );
    content = content.replace(
        \              children: [\\n                TextField(\\n                  controller: tempNameController,\,
        newDialogFields
    );

    content = content.replace(
        \_nameController.text = tempNameController.text.trim();\\r\\n                  _upiController.text = tempUpiController.text.trim();\,
        \_nameController.text = tempNameController.text.trim();\\n                  _phoneController.text = tempPhoneController.text.trim();\\n                  _upiController.text = tempUpiController.text.trim();\
    );
    content = content.replace(
        \_nameController.text = tempNameController.text.trim();\\n                  _upiController.text = tempUpiController.text.trim();\,
        \_nameController.text = tempNameController.text.trim();\\n                  _phoneController.text = tempPhoneController.text.trim();\\n                  _upiController.text = tempUpiController.text.trim();\
    );

    content = content.replace(
        \inal name = _nameController.text.trim().isNotEmpty\\r\\n          ? _nameController.text.trim()\\r\\n          : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Sikka User');\,
        \inal name = _nameController.text.trim().isNotEmpty\\n          ? _nameController.text.trim()\\n          : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Sikka User');\\n\\n      final phone = _phoneController.text.trim().isNotEmpty\\n          ? _phoneController.text.trim()\\n          : ((widget.initialPhone != null && widget.initialPhone!.isNotEmpty) ? widget.initialPhone! : 'Not Provided');\
    );
    content = content.replace(
        \inal name = _nameController.text.trim().isNotEmpty\\n          ? _nameController.text.trim()\\n          : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Sikka User');\,
        \inal name = _nameController.text.trim().isNotEmpty\\n          ? _nameController.text.trim()\\n          : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Sikka User');\\n\\n      final phone = _phoneController.text.trim().isNotEmpty\\n          ? _phoneController.text.trim()\\n          : ((widget.initialPhone != null && widget.initialPhone!.isNotEmpty) ? widget.initialPhone! : 'Not Provided');\
    );

    content = content.replace(
        '_showReceiptModal(amountCoins, totalRupees, feeRupees, netRupees, cashbackCoins, upiId, name, selectedOptionId);',
        '_showReceiptModal(amountCoins, totalRupees, feeRupees, netRupees, cashbackCoins, upiId, name, phone, selectedOptionId);'
    );

    content = content.replace(
        '_showReceiptModal(int coins, int totalRupees, int feeRupees, int netRupees, int cashbackCoins, String upiId, String name, String? optionId)',
        '_showReceiptModal(int coins, int totalRupees, int feeRupees, int netRupees, int cashbackCoins, String upiId, String name, String phone, String? optionId)'
    );

    content = content.replace(
        '_executeFinalWithdraw(coins, netRupees, cashbackCoins, upiId, name, optionId);',
        '_executeFinalWithdraw(coins, netRupees, cashbackCoins, upiId, name, phone, optionId);'
    );

    content = content.replace(
        '_executeFinalWithdraw(int coins, int netRupees, int cashbackCoins, String upiId, String name, String? optionId)',
        '_executeFinalWithdraw(int coins, int netRupees, int cashbackCoins, String upiId, String name, String phone, String? optionId)'
    );

    content = content.replace(
        'widget.onWithdraw(coins, netRupees, cashbackCoins, upiId, name, optionId);',
        'widget.onWithdraw(coins, netRupees, cashbackCoins, upiId, name, phone, optionId);'
    );
    
    content = content.replace(
        'widget.onWithdraw(coins, netRupees, cashbackCoins, upiId, name, optionId)',
        'widget.onWithdraw(coins, netRupees, cashbackCoins, upiId, name, phone, optionId)'
    );

    const oldText = \Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Enter Full Name'),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                          ),\;
    const newText = \Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : ((widget.initialName != null && widget.initialName!.isNotEmpty) ? widget.initialName! : 'Enter Full Name'),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                          ),
                          if (_phoneController.text.isNotEmpty || (widget.initialPhone != null && widget.initialPhone!.isNotEmpty))
                            Text(
                              _phoneController.text.isNotEmpty ? _phoneController.text : widget.initialPhone!,
                              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF475569)),
                            ),\;
    content = content.replace(oldText, newText);
    content = content.replace(oldText.replace(/\\n/g, '\\r\\n'), newText);

    content = content.replace(
        \inal savedUpiId = userData['upiId'] as String?;\\r\\n    final savedName = userData['name'] as String?;\,
        \inal savedUpiId = userData['upiId'] as String?;\\n    final savedName = userData['name'] as String?;\\n    final savedPhone = userData['phone'] as String? ?? userData['phoneNumber'] as String?;\
    );
    content = content.replace(
        \inal savedUpiId = userData['upiId'] as String?;\\n    final savedName = userData['name'] as String?;\,
        \inal savedUpiId = userData['upiId'] as String?;\\n    final savedName = userData['name'] as String?;\\n    final savedPhone = userData['phone'] as String? ?? userData['phoneNumber'] as String?;\
    );

    content = content.replace(
        'initialName: savedName,\\n',
        'initialName: savedName,\\n              initialPhone: savedPhone,\\n'
    );
    content = content.replace(
        'initialName: savedName,\\r\\n',
        'initialName: savedName,\\n              initialPhone: savedPhone,\\n'
    );

    content = content.replace(
        'onWithdraw: (coinsAmount, netRupees, cashbackCoins, upiId, name, optionId) async {',
        'onWithdraw: (coinsAmount, netRupees, cashbackCoins, upiId, name, phone, optionId) async {'
    );

    content = content.replace(
        \ef.read(homeProvider.notifier).requestWithdrawal(\\r\\n                  coinsAmount,\\r\\n                  upiId,\\r\\n                  name,\\r\\n                  earningType: earningType,\\r\\n                  optionId: optionId,\\r\\n                );\,
        \ef.read(homeProvider.notifier).requestWithdrawal(\\n                  coinsAmount,\\n                  upiId,\\n                  name,\\n                  phone,\\n                  earningType: earningType,\\n                  optionId: optionId,\\n                );\
    );
    content = content.replace(
        \ef.read(homeProvider.notifier).requestWithdrawal(\\n                  coinsAmount,\\n                  upiId,\\n                  name,\\n                  earningType: earningType,\\n                  optionId: optionId,\\n                );\,
        \ef.read(homeProvider.notifier).requestWithdrawal(\\n                  coinsAmount,\\n                  upiId,\\n                  name,\\n                  phone,\\n                  earningType: earningType,\\n                  optionId: optionId,\\n                );\
    );

    fs.writeFileSync(path, content, 'utf8');
}

try {
    updateWalletScreen();
    console.log('Wallet screen successfully patched!');
} catch (e) {
    console.error('Error:', e);
}
