import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/constants/app_sizes.dart';
import 'package:sikkaplay/shared/widgets/premium_card.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/main.dart';
import 'package:sikkaplay/routes/app_router.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  List<dynamic> _faqs = [];
  List<dynamic> _tickets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
      _fetchFaqs();
      if (_isLoggedIn) {
        _fetchTickets();
      }
    }
  }

  Future<void> _fetchFaqs() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '')}/support/faqs'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _faqs = data['faqs']);
      }
    } catch (e) {
      debugPrint('Failed to fetch FAQs: $e');
    }
  }

  Future<void> _handleAuthError(int statusCode, dynamic body) async {
    await AuthService().logout();
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null) {
      while (navigator.canPop()) {
        navigator.pop();
      }
    }
    String errorMsg = statusCode == 403
        ? 'Your account has been suspended.'
        : 'Session expired. Please log in again.';
    try {
      errorMsg = body['error'] ?? errorMsg;
    } catch (_) {}

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(statusCode == 403 ? Icons.block_rounded : Icons.logout_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMsg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _fetchTickets() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '')}/support/tickets'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError(response.statusCode, jsonDecode(response.body));
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _tickets = data['tickets']);
      }
    } catch (e) {
      debugPrint('Failed to fetch tickets: $e');
    }
  }

  Future<void> _submitTicket(String language) async {
    if (_nameController.text.isEmpty || _mobileController.text.isEmpty || _issueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(language == 'Hindi' ? 'कृपया सभी फ़ील्ड भरें' : 'Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/auth', '')}/support/tickets'),
        headers: headers,
        body: jsonEncode({
          'name': _nameController.text,
          'mobile': _mobileController.text,
          'issue': _issueController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (token != null && (response.statusCode == 401 || response.statusCode == 403)) {
        await _handleAuthError(response.statusCode, data);
        return;
      }

      if (response.statusCode == 201) {
        messenger.showSnackBar(
          SnackBar(content: Text(language == 'Hindi' ? 'टिकट सफलतापूर्वक सबमिट हो गया' : 'Ticket Submitted successfully')),
        );
        _issueController.clear();
        if (token != null) {
          _fetchTickets();
          _tabController.animateTo(2); // Move to tickets tab
        } else {
          _nameController.clear();
          _mobileController.clear();
        }
      } else {
        messenger.showSnackBar(SnackBar(content: Text(data['error'] ?? 'Failed to submit ticket')));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(language == 'Hindi' ? 'सर्वर से कनेक्ट करने में त्रुटि' : 'Error connecting to server')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, String> _getLocalizedFaq(String question, String answer, String language) {
    if (language != 'Hindi') return {'question': question, 'answer': answer};

    final qLower = question.toLowerCase();
    if (qLower.contains('what is sikkaplay')) {
      return {
        'question': 'सिक्काप्ले (SikkaPlay) क्या है?',
        'answer': 'सिक्काप्ले एक प्रीमियम रिवॉर्ड-आधारित गेमिंग प्लेटफॉर्म है जहां आप गेम खेल सकते हैं, सरल दैनिक कार्यों को पूरा कर सकते हैं, रील्स देख सकते हैं, और सिक्का (Sikka) सिक्के कमाने के लिए दोस्तों को रेफर कर सकते हैं। इन सिक्कों को सीधे UPI के माध्यम से निकाला जा सकता है।'
      };
    } else if (qLower.contains('how do i earn')) {
      return {
        'question': 'मैं सिक्का सिक्के कैसे कमाऊं?',
        'answer': 'सिक्का सिक्के कमाने के कई तरीके हैं:\n1. रील्स देखें: रील्स देखने पर लगातार सिक्के कमाएं।\n2. गेम खेलें: इमोजी मेमोरी, मैथ रश, ट्रेजर ग्रिड या लकी स्पिन व्हील खेलें।\n3. डेली कोड: बोनस सिक्का के लिए दैनिक प्रोमो कोड क्लेम करें।\n4. कार्य और सर्वेक्षण: प्रायोजित वेबसाइटों पर जाएं या पार्टनर सर्वेक्षण पूरे करें।\n5. सोशलतास्कर: हमारे आधिकारिक टेलीग्राम और व्हाट्सएप चैनलों से जुड़ें।'
      };
    } else if (qLower.contains('how can i withdraw') || qLower.contains('minimum limit')) {
      return {
        'question': 'मैं अपने सिक्के कैसे निकाल सकता हूँ और न्यूनतम सीमा क्या है?',
        'answer': 'वॉलेट सेक्शन में जाएं, अपनी UPI आईडी दर्ज करें, और निकासी का अनुरोध करें। न्यूनतम निकासी सीमा 1,000 सिक्का सिक्के है (100 सिक्का = 1 रुपये)।'
      };
    } else if (qLower.contains('referral/network')) {
      return {
        'question': 'रेफरल/नेटवर्क अर्निंग प्रोग्राम क्या है?',
        'answer': 'जब आप किसी मित्र को रेफर करते हैं, तो आप तुरंत 500 सिक्का कमाते हैं। आप अपने प्रत्यक्ष और अप्रत्यक्ष नेटवर्क सदस्यों (लेवल 3 तक) द्वारा की गई सभी निकासियों पर 10% कमीशन भी कमाते हैं!'
      };
    } else if (qLower.contains('emoji memory')) {
      return {
        'question': 'इमोजी मेमोरी के क्या नियम हैं?',
        'answer': 'राउंड की शुरुआत में, बोर्ड 5-सेकंड के पूर्वावलोकन के लिए खुलता है। कार्ड की स्थिति याद रखें। फिर, बबल में दिखाए गए लक्षित इमोजी से मेल खाने वाले कार्डों का अनुमान लगाएं। सही अनुमान: +3 सिक्का। आपके पास प्रति राउंड अधिकतम 3 गलतियां करने का मौका है।'
      };
    } else if (qLower.contains('math rush')) {
      return {
        'question': 'मैथ रश के क्या नियम हैं?',
        'answer': 'समय सीमा के भीतर समीकरणों को हल करें। आप चार मोड्स में से चुन सकते हैं:\n- डिफॉल्ट: प्रगतिशील कठिनाई, 10s टाइमर, +2 सिक्का प्रति सही उत्तर।\n- आसान: स्थिर आसान प्रश्न, 10s टाइमर, +1 सिक्का।\n- मध्यम: स्थिर मध्यम प्रश्न, 8s टाइमर, +2 सिक्का।\n- कठिन: स्थिर कठिन प्रश्न, 6s टाइमर, +3 सिक्का।'
      };
    } else if (qLower.contains('treasure grid')) {
      return {
        'question': 'ट्रेजर ग्रिड के क्या नियम हैं?',
        'answer': 'ग्रिड पर 3 कार्ड स्थितियों का चयन करें। यदि वे खजाने से मेल खाते हैं, तो आप सिक्के जीतते हैं। यदि आप क्लेम करने के लिए वीडियो विज्ञापन नहीं देखना चुनते हैं, तो आपकी जीत से एक बाईपास शुल्क काट लिया जाता है। यदि आप हार जाते हैं, तो राउंड रीसेट हो जाता है।'
      };
    } else if (qLower.contains('lucky spin')) {
      return {
        'question': 'लकी स्पिन व्हील के क्या नियम हैं?',
        'answer': 'हर दिन आपको 3 मुफ्त स्पिन मिलते हैं। 1 से 30 सिक्का तक के पुरस्कार जीतने के लिए पहिया घुमाएं। यदि आपके स्पिन समाप्त हो जाते हैं, तो आप 3 और स्पिन प्राप्त करने के लिए एक रिवॉर्डेड वीडियो विज्ञापन देख सकते हैं। स्पिन 100% मुफ्त हैं!'
      };
    }
    return {'question': question, 'answer': answer};
  }

  String _translateTicketStatus(String status, String language) {
    if (language != 'Hindi') return status.toUpperCase();
    final lower = status.toLowerCase();
    if (lower == 'resolved') return 'सुलझाया गया';
    if (lower == 'in_progress') return 'प्रगति पर है';
    return 'लंबित';
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('help_support', selectedLanguage),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: context.tr('faqs_tab', selectedLanguage)),
            Tab(text: context.tr('raise_ticket_tab', selectedLanguage)),
            Tab(text: context.tr('my_tickets_tab', selectedLanguage)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqsTab(selectedLanguage),
          _buildRaiseTicketTab(selectedLanguage),
          _buildMyTicketsTab(selectedLanguage),
        ],
      ),
    );
  }

  Widget _buildFaqsTab(String language) {
    if (_faqs.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_faqs', language),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        final mapped = _getLocalizedFaq(faq['question'], faq['answer'], language);
        return PremiumCard(
          padding: const EdgeInsets.all(0),
          child: ExpansionTile(
            title: Text(mapped['question']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(mapped['answer']!, style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRaiseTicketTab(String language) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('need_help', language), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(context.tr('support_subtitle', language), style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          _buildTextField(context.tr('full_name_label', language), context.tr('full_name_hint', language), _nameController),
          const SizedBox(height: 16),
          _buildTextField(context.tr('mobile_number_label', language), context.tr('mobile_number_hint', language), _mobileController, isNumber: true),
          const SizedBox(height: 16),
          _buildTextField(context.tr('describe_issue_label', language), context.tr('describe_issue_hint', language), _issueController, maxLines: 4),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitTicket(language),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(context.tr('submit_ticket_btn', language), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildMyTicketsTab(String language) {
    if (!_isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                context.tr('login_required_title', language),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('login_required_desc', language),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Exit support
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.tr('go_to_login_btn', language), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(child: Text(context.tr('no_tickets', language), style: const TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        Color statusColor = Colors.orange;
        if (ticket['status'] == 'resolved') statusColor = Colors.green;
        if (ticket['status'] == 'in_progress') statusColor = Colors.blue;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: PremiumCard(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${context.tr('ticket_id', language)}${ticket['id'].toString().substring(0, 6)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_translateTicketStatus(ticket['status'], language), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(ticket['issue'], style: const TextStyle(color: AppColors.textPrimary)),
                if (ticket['reply'] != null) ...[
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('admin_reply', language), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(ticket['reply'], style: const TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
