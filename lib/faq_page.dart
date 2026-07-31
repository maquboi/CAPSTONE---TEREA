import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _faqs = [];

  // Theme Palette (Matching your Dashboard)
  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);  
  final Color mossGreen = const Color(0xFFADC178);
  final Color paleGreen = const Color(0xFFDDE5B6);
  final Color softWhite = const Color(0xFFF9FBF9);

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      final response = await _supabase
          .from('faqs')
          .select()
          .order('created_at', ascending: true);
          
      if (mounted) {
        setState(() {
          _faqs = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load guidelines. Please check your connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softWhite,
      appBar: AppBar(
        backgroundColor: softWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: forestDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'DOH Guidelines',
          style: TextStyle(fontWeight: FontWeight.w900, color: forestDark, fontSize: 22, letterSpacing: 0.5),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: forestMed))
          : RefreshIndicator(
              onRefresh: _fetchFaqs,
              color: forestMed,
              backgroundColor: Colors.white,
              child: _faqs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      itemCount: _faqs.length,
                      itemBuilder: (context, index) {
                        final faq = _faqs[index];
                        return _buildFaqCard(faq['question'], faq['answer'], faq['category']);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: paleGreen),
            const SizedBox(height: 16),
            Text(
              "No guidelines available.",
              style: TextStyle(color: forestDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check back later or refresh the page.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard(String question, String answer, String? category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        // Removes the default borders from ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: forestMed,
          collapsedIconColor: forestDark,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: paleGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(color: forestMed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                question,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: forestDark, height: 1.3),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: softWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                answer,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}