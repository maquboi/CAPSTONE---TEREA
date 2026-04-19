import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Required for Text-to-Speech

// --- 5. ASSESSMENT PAGE & RESULT LOGIC ---
class AssessmentPage extends StatefulWidget {
  const AssessmentPage({super.key});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  int currentIndex = 0;
  
  // Track all user answers to allow moving back and forth easily
  late List<String?> userAnswers;
  bool _showError = false;
  
  // Feature Options: Summary View & Bilingual Toggle
  bool _showSummary = false;
  bool _isTagalog = false;

  // Text-to-Speech Instance
  final FlutterTts flutterTts = FlutterTts();

  // Bilingual Questions, Descriptions, AND Medical Icons
  final List<Map<String, dynamic>> questions = [
    {
      "q_en": "Do you have a persistent cough lasting more than 2 weeks?",
      "q_tl": "May matinding ubo ka ba na tumagal na ng higit sa 2 linggo?",
      "desc_en": "A continuous cough that does not seem to get better with standard cold medicine.",
      "desc_tl": "Walang tigil na ubo na hindi gumagaling sa mga karaniwang gamot sa sipon.",
      "weight": 3,
      "icon": Icons.coronavirus_outlined
    }, 
    {
      "q_en": "Have you noticed blood in your phlegm or mucus?",
      "q_tl": "May nakita ka bang dugo sa iyong plema?",
      "desc_en": "Even small streaks of blood when you cough up phlegm.",
      "desc_tl": "Kahit maliliit na bahid ng dugo kapag inuubo ka ng plema.",
      "weight": 5,
      "icon": Icons.water_drop_outlined
    }, 
    {
      "q_en": "Have you experienced unexplained weight loss recently?",
      "q_tl": "Naranasan mo ba ang biglaang pagbaba ng timbang?",
      "desc_en": "Losing weight without actively trying through diet or exercise.",
      "desc_tl": "Pagpayat nang hindi naman nag-dyedieta o nag-eehersisyo.",
      "weight": 2,
      "icon": Icons.monitor_weight_outlined
    }, 
    {
      "q_en": "Do you suffer from frequent night sweats?",
      "q_tl": "Madalas ka bang pinagpapawisan tuwing gabi?",
      "desc_en": "Sweating heavily during sleep, often enough to soak your clothes or bedsheets.",
      "desc_tl": "Labis na pagpapawis habang natutulog, na nakakabasa ng damit o kumot.",
      "weight": 2,
      "icon": Icons.bedtime_outlined
    }, 
    {
      "q_en": "Do you have persistent chest pain or pain when breathing?",
      "q_tl": "May matindi ka bang pananakit ng dibdib o hirap sa paghinga?",
      "desc_en": "A sharp or dull ache in your chest that worsens when inhaling deeply or coughing.",
      "desc_tl": "Matulis o mabigat na sakit sa dibdib na lumalala kapag humihinga nang malalim o umuubo.",
      "weight": 2,
      "icon": Icons.monitor_heart_outlined
    },
    {
      "q_en": "Have you been feeling unusually tired or fatigued for weeks?",
      "q_tl": "Nakakaramdam ka ba ng labis na pagod o panghihina ng ilang linggo?",
      "desc_en": "A constant feeling of exhaustion that doesn't improve with rest.",
      "desc_tl": "Walang tigil na pakiramdam ng pagod na hindi nawawala kahit nagpahinga.",
      "weight": 1,
      "icon": Icons.battery_alert_outlined
    },
    {
      "q_en": "Do you have a recurring fever (especially in the afternoon)?",
      "q_tl": "Mayroon ka bang pabalik-balik na lagnat (lalo na tuwing hapon)?",
      "desc_en": "A slightly elevated temperature that tends to rise later in the day.",
      "desc_tl": "Bahagyang pagtaas ng temperatura na madalas mangyari sa hapon o gabi.",
      "weight": 2,
      "icon": Icons.thermostat_outlined
    }, 
    {
      "q_en": "Have you lost your appetite significantly?",
      "q_tl": "Nawalan ka ba ng gana sa pagkain?",
      "desc_en": "Lack of desire to eat your normal daily meals.",
      "desc_tl": "Kakulangan ng ganang kumain ng iyong mga karaniwang pagkain.",
      "weight": 1,
      "icon": Icons.restaurant_outlined
    },
    {
      "q_en": "Have you lived with or cared for someone with active TB?",
      "q_tl": "May kasama ka ba sa bahay o inalagaan na may aktibong TB?",
      "desc_en": "Close, prolonged indoor contact with a known Tuberculosis patient.",
      "desc_tl": "Matagal at malapit na pakikisalamuha sa isang kilalang pasyenteng may Tuberculosis.",
      "weight": 4,
      "icon": Icons.people_outline
    }, 
    {
      "q_en": "Do you have a weakened immune system?",
      "q_tl": "Mayroon ka bang mahinang immune system?",
      "desc_en": "Conditions such as Diabetes, HIV/AIDS, or undergoing immune-suppressing treatments.",
      "desc_tl": "Mga kondisyon tulad ng Diabetes, HIV/AIDS, o umiinom ng mga gamot na nagpapababa ng resistensya.",
      "weight": 3,
      "icon": Icons.health_and_safety_outlined
    }, 
    {
      "q_en": "Have you recently traveled to an area with high TB rates?",
      "q_tl": "Nagpunta ka ba kamakailan sa lugar na may mataas na kaso ng TB?",
      "desc_en": "Extended stays in highly congested or vulnerable areas.",
      "desc_tl": "Matagal na pananatili sa mga siksikan o mapanganib na lugar.",
      "weight": 2,
      "icon": Icons.flight_takeoff_outlined
    },
    {
      "q_en": "Do you smoke or have a history of heavy tobacco use?",
      "q_tl": "Naninigarilyo ka ba o may kasaysayan ng labis na paninigarilyo?",
      "desc_en": "Current smoking habits or a long-term history of smoking.",
      "desc_tl": "Kasalukuyang naninigarilyo o may matagal na kasaysayan ng paninigarilyo.",
      "weight": 1,
      "icon": Icons.smoking_rooms_outlined
    },
  ];

  // Theme Colors
  final Color forestDark = const Color(0xFF283618);
  final Color forestMed = const Color(0xFF606C38);
  final Color mossGreen = const Color(0xFFADC178);
  final Color paleGreen = const Color(0xFFDDE5B6);

  @override
  void initState() {
    super.initState();
    userAnswers = List.filled(questions.length, null);
    
    // Configure TTS
    flutterTts.setSpeechRate(0.45);
    flutterTts.setPitch(1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartDialog();
    });
  }

  @override
  void dispose() {
    flutterTts.stop(); // Stop audio when leaving the page
    super.dispose();
  }

  // Read aloud function
  Future<void> _speakText(String title, String description) async {
    await flutterTts.stop(); // Stop any currently playing audio
    await flutterTts.setLanguage(_isTagalog ? "tl-PH" : "en-US");
    await flutterTts.speak("$title. $description");
  }

  Future<void> _showStartDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Start Assessment', style: TextStyle(color: forestDark, fontWeight: FontWeight.bold)),
          content: const Text(
            'This assessment will ask you a series of questions to determine your risk level for Tuberculosis. Please answer honestly.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.of(context).pop(); 
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: forestMed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start Now', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleNext() {
    flutterTts.stop(); // Stop audio when switching pages
    if (userAnswers[currentIndex] == null) {
      setState(() => _showError = true);
      return;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        _showError = false;
      });
    } else {
      setState(() {
        _showSummary = true;
      });
    }
  }

  void _handlePrevious() {
    flutterTts.stop(); // Stop audio when switching pages
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _showError = false;
      });
    }
  }

  Future<void> _calculateAndNavigate() async {
    int finalScore = 0;
    bool hasRedFlag = false;
    bool isSymptomatic = false;
    bool isCloseContact = false;
    bool isVulnerable = false;

    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == "Yes") {
        finalScore += (questions[i]['weight'] as int);

        if (i == 1) hasRedFlag = true;
        if (i == 0 || i == 2 || i == 3 || i == 6) isSymptomatic = true;
        if (i == 8) isCloseContact = true;
        if (i == 9 || i == 11) isVulnerable = true;
      }
    }

    String finalRisk = "Low Risk";

    if (hasRedFlag || (isSymptomatic && finalScore >= 10) || finalScore >= 12) {
      finalRisk = "High Risk";
    } 
    else if (isSymptomatic || isCloseContact || isVulnerable || finalScore >= 6) {
      finalRisk = "Medium Risk";
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'risk_level': finalRisk,
              'is_symptomatic': isSymptomatic,
              'is_close_contact': isCloseContact,
              'is_vulnerable': isVulnerable,
            })
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error updating database: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/result', arguments: finalScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _showSummary ? _buildSummaryView() : _buildQuestionView(),
    );
  }

  Widget _buildQuestionView() {
    String qText = _isTagalog ? questions[currentIndex]['q_tl'] : questions[currentIndex]['q_en'];
    String descText = _isTagalog ? questions[currentIndex]['desc_tl'] : questions[currentIndex]['desc_en'];
    IconData currentIcon = questions[currentIndex]['icon'];

    return Column(
      children: [
        Container(
          // Reduced bottom padding to firmly pull the progress bar section up
          padding: const EdgeInsets.fromLTRB(25, 50, 25, 15),
          decoration: BoxDecoration(
            color: forestDark,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context), 
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Text('TB Risk Assessment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () {
                      flutterTts.stop(); // Stop audio if language changes
                      setState(() => _isTagalog = !_isTagalog);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                       decoration: BoxDecoration(
                         color: mossGreen.withOpacity(0.2),
                         border: Border.all(color: mossGreen), 
                         borderRadius: BorderRadius.circular(12)
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.language, color: paleGreen, size: 14),
                           const SizedBox(width: 4),
                           Text(_isTagalog ? "TL" : "EN", style: TextStyle(color: paleGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                         ],
                       ),
                    ),
                  ),
                ],
              ),
              // Minimized gap to bring step counter up
              const SizedBox(height: 10),
              Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                    Text('Step ${currentIndex + 1}/${questions.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                 ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (currentIndex + 1) / questions.length,
                color: mossGreen,
                backgroundColor: Colors.white24,
              ),
            ],
          ),
        ),
        
        // AnimatedSwitcher for smooth transitions
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0.0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              key: ValueKey<int>(currentIndex), 
              // Changed top padding to 0 to pull questions as high as possible
              padding: const EdgeInsets.fromLTRB(25, 5, 25, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical Iconography
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(
                      color: paleGreen.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(currentIcon, size: 28, color: forestMed),
                  ),
                  const SizedBox(height: 15), 
                  
                  // Question and Text-to-Speech Button aligned perfectly
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(qText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: forestDark, height: 1.2)),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.volume_up_rounded, color: mossGreen, size: 28),
                        onPressed: () => _speakText(qText, descText),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(descText, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
                  const SizedBox(height: 25), 
                  
                  _buildOption("Yes"),
                  const SizedBox(height: 15),
                  _buildOption("No"),
                  
                  if (_showError) Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(_isTagalog ? "Pumili muna ng sagot para makapagpatuloy." : "Please select an option to proceed.", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(25),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Row(
              children: [
                if (currentIndex > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: forestMed, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _handlePrevious,
                      child: Text(_isTagalog ? "Bumalik" : "Back", style: TextStyle(color: forestMed, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forestMed, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _handleNext,
                    child: Text(currentIndex < questions.length - 1 ? (_isTagalog ? "Susunod" : "Next Step") : (_isTagalog ? "Suriin" : "Review"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SUMMARY REVIEW SCREEN ---
  Widget _buildSummaryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(25, 50, 25, 15), // Adjusted to match question view
          decoration: BoxDecoration(
            color: forestDark,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => setState(() => _showSummary = false), 
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(_isTagalog ? 'Suriin ang mga Sagot' : 'Review Answers', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () => setState(() => _isTagalog = !_isTagalog),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                   decoration: BoxDecoration(
                     color: mossGreen.withOpacity(0.2),
                     border: Border.all(color: mossGreen), 
                     borderRadius: BorderRadius.circular(12)
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.language, color: paleGreen, size: 14),
                       const SizedBox(width: 4),
                       Text(_isTagalog ? "TL" : "EN", style: TextStyle(color: paleGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                     ],
                   ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 25), // Adjusted top padding
            itemCount: questions.length,
            itemBuilder: (context, index) {
              String qText = _isTagalog ? questions[index]['q_tl'] : questions[index]['q_en'];
              String answer = userAnswers[index] ?? "N/A";
              String displayAnswer = answer == "Yes" ? (_isTagalog ? "Oo (Yes)" : "Yes") : (_isTagalog ? "Hindi (No)" : "No");
              IconData rowIcon = questions[index]['icon'];

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 2)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(rowIcon, color: mossGreen, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Q${index + 1}: $qText", style: TextStyle(fontWeight: FontWeight.bold, color: forestDark, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text("${_isTagalog ? 'Sagot' : 'Answer'}: $displayAnswer", style: TextStyle(color: answer == "Yes" ? Colors.red[700] : forestMed, fontWeight: FontWeight.bold, fontSize: 16)),
                        ]
                      )
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_note_rounded, color: mossGreen, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                         setState((){ 
                           _showSummary = false; 
                           currentIndex = index; 
                         });
                      }
                    )
                  ]
                )
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(25),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: forestMed, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _calculateAndNavigate,
              child: Text(_isTagalog ? "Ipasa ang Pagsusuri" : "Submit Assessment", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(String internalValue) {
    bool isSel = userAnswers[currentIndex] == internalValue;
    
    String displayLabel = internalValue;
    if (internalValue == "Yes") displayLabel = _isTagalog ? "Oo (Yes)" : "Yes";
    if (internalValue == "No") displayLabel = _isTagalog ? "Hindi (No)" : "No";

    return InkWell(
      onTap: () {
        setState(() {
          userAnswers[currentIndex] = internalValue; 
          _showError = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSel ? paleGreen.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? forestMed : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Icon(isSel ? Icons.check_circle : Icons.circle_outlined, color: isSel ? forestMed : Colors.grey),
            const SizedBox(width: 15),
            Text(displayLabel, style: TextStyle(fontSize: 18, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: forestDark)),
          ],
        ),
      ),
    );
  }
}