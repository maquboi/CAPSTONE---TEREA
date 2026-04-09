import 'package:flutter/material.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _messageController = TextEditingController();
  
  // THEME PALETTE (Matched to your app)
  final Color kPrimaryGreen = const Color(0xFF283618);
  final Color kSecondaryGreen = const Color(0xFF606C38);
  final Color kCreamAccent = const Color(0xFFFEFAE0);
  final Color kWhite = Colors.white;
  final Color kSoftGrey = const Color(0xFFF8F9FA);

  // FAQ State
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I link my account to a doctor?",
      "answer": "Go to your dashboard, click on the 'Link Clinic' option, and enter the unique code provided by your doctor or barangay health worker."
    },
    {
      "question": "Why is my Medication Diary locked?",
      "answer": "The diary remains locked until you have taken your initial Risk Assessment and a verified doctor has approved your connection and set your treatment start date."
    },
    {
      "question": "How do I edit a mistaken diary entry?",
      "answer": "Go to the Meds Page, tap the three dots (more options) next to the medication, and select 'Edit' or uncheck the circle if you accidentally marked it as taken."
    },
    {
      "question": "Who can see my health data?",
      "answer": "Your health data is strictly confidential and is only shared with your linked healthcare provider (doctor) to monitor your TB treatment roadmap."
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_messageController.text.isEmpty) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Clear the field and show confirmation
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Message sent! Support will contact you shortly."),
        backgroundColor: kPrimaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite, 
        elevation: 0, 
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryGreen, size: 20), 
          onPressed: () => Navigator.of(context).pop()
        ),
        title: Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900, color: kPrimaryGreen, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(),
            const SizedBox(height: 25),
            
            // QUICK CONTACT SECTION
            Text("QUICK CONTACT", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildContactCard(Icons.call_rounded, "Call Clinic", "Available 8AM-5PM")),
                const SizedBox(width: 15),
                Expanded(child: _buildContactCard(Icons.email_rounded, "Email Us", "Expect a reply in 24h")),
              ],
            ),
            const SizedBox(height: 35),

            // FAQ SECTION
            Text("FREQUENTLY ASKED", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            ...List.generate(_faqs.length, (index) => _buildFAQItem(index)),
            
            const SizedBox(height: 35),

            // SUBMIT A TICKET SECTION
            Text("REPORT AN ISSUE", style: TextStyle(color: kSecondaryGreen, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 15),
            _buildSupportForm(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildModernHeader() { 
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kSecondaryGreen, kPrimaryGreen], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ), 
        borderRadius: BorderRadius.circular(24)
      ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text('How can we help you today?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)), 
              ),
            ],
          ),
          const SizedBox(height: 15), 
          Text('Find answers below or send us a message directly.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)), 
        ]
      )
    ); 
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSoftGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kSecondaryGreen, size: 28),
          const SizedBox(height: 15),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryGreen, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(int index) {
    bool isExpanded = _expandedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded ? kCreamAccent : kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isExpanded ? kSecondaryGreen.withOpacity(0.3) : kSoftGrey, width: 2)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _faqs[index]["question"]!, 
                    style: TextStyle(fontWeight: FontWeight.w700, color: kPrimaryGreen, fontSize: 14)
                  )
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? kSecondaryGreen : Colors.grey,
                )
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                _faqs[index]["answer"]!, 
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5)
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSupportForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kSoftGrey, width: 2)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kSoftGrey, 
              borderRadius: BorderRadius.circular(16)
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe the issue you are facing or any questions you have...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen, 
                padding: const EdgeInsets.symmetric(vertical: 16), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0
              ),
              onPressed: _submitTicket,
              child: const Text("Send Message", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}