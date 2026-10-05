import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _showRationale = false;

  // Feature Options: Summary View & Bilingual Toggle
  bool _showSummary = false;
  bool _isTagalog = false;

  // Text-to-Speech Instance
  final FlutterTts flutterTts = FlutterTts();

  // --- FORMAL CLINICAL COLOR SYSTEM ---
  static const Color primaryTeal = Color(0xFF0F766E);       // Deep Clinical Teal
  static const Color primaryDark = Color(0xFF115E59);       // Spruce Slate
  static const Color primaryDeep = Color(0xFF042F2E);       // Deepest Navy Teal
  static const Color backgroundSurface = Color(0xFFF1F5F9); // Contrast Slate Background
  static const Color cardBg = Colors.white;                // Pure White Card
  static const Color textCharcoal = Color(0xFF0F172A);      // High Contrast Text
  static const Color textMuted = Color(0xFF64748B);         // Subdued Text
  static const Color borderNeutral = Color(0xFFE2E8F0);     // Structured Border

  // Clinically Structured DOH Protocol Questions
  final List<Map<String, dynamic>> questions = [
    {
      "category_en": "Cardinal Respiratory Symptoms",
      "category_tl": "Pangunahing Sintomas sa Baga",
      "phase_num": 1,
      "q_en": "Do you have a persistent cough lasting more than 2 weeks?",
      "q_tl": "May matinding ubo ka ba na tumagal na ng higit sa 2 linggo?",
      "desc_en": "A continuous cough that does not resolve with standard over-the-counter medication.",
      "desc_tl": "Walang tigil na ubo na hindi gumagaling sa mga karaniwang gamot sa sipon.",
      "rationale_en": "Under DOH clinical guidelines, a cough extending beyond 14 days qualifies an individual as a Presumptive TB case requiring bacteriological sputum evaluation.",
      "rationale_tl": "Ayon sa panuntunan ng DOH, ang ubong higit sa 14 na araw ay pangunahing basehan ng Presumptive TB na nangangailangan ng pagsusuri sa plema.",
      "weight": 3,
      "is_cardinal": true,
      "icon": Icons.coronavirus_outlined
    },
    {
      "category_en": "Cardinal Respiratory Symptoms",
      "category_tl": "Pangunahing Sintomas sa Baga",
      "phase_num": 1,
      "q_en": "Have you noticed blood in your phlegm or mucus (Hemoptysis)?",
      "q_tl": "May nakita ka bang dugo sa iyong plema (Hemoptysis)?",
      "desc_en": "Visible reddish discoloration or blood streaks present when coughing up sputum.",
      "desc_tl": "Kahit maliliit na bahid ng dugo kapag inuubo ka ng plema.",
      "rationale_en": "Hemoptysis indicates parenchymal tissue erosion or vascular lung involvement, serving as a critical diagnostic red-flag indicator.",
      "rationale_tl": "Ang dugo sa plema ay senyales ng pagkasugat sa tisyu ng baga at itinuturing na agarang red-flag na sintomas.",
      "weight": 5,
      "is_cardinal": true,
      "icon": Icons.water_drop_outlined
    },
    {
      "category_en": "Constitutional Systemic Signs",
      "category_tl": "Pangkalahatang Sintomas sa Katawan",
      "phase_num": 1,
      "q_en": "Have you experienced unexplained or involuntary weight loss?",
      "q_tl": "Naranasan mo ba ang biglaang pagbaba ng timbang nang walang dahilan?",
      "desc_en": "Noticeable weight reduction without intentional dieting or elevated physical exercise.",
      "desc_tl": "Pagpayat nang hindi naman nag-dyedieta o nag-eehersisyo.",
      "rationale_en": "Systemic cachexia occurs due to increased metabolic demands and chronic cytokine release induced by active mycobacterial infection.",
      "rationale_tl": "Ang biglaang pagpayat ay dulot ng mataas na metabolic demand habang nilalabanan ng katawan ang impeksyon.",
      "weight": 2,
      "is_cardinal": false,
      "icon": Icons.monitor_weight_outlined
    },
    {
      "category_en": "Constitutional Systemic Signs",
      "category_tl": "Pangkalahatang Sintomas sa Katawan",
      "phase_num": 1,
      "q_en": "Do you suffer from recurrent, drenching night sweats?",
      "q_tl": "Madalas ka bang pinagpapawisan nang labis tuwing gabi?",
      "desc_en": "Excessive sweating during sleep that soaks your clothing or bedsheets despite normal room temperature.",
      "desc_tl": "Labis na pagpapawis habang natutulog na nakakabasa ng damit o kumot kahit malamig ang silid.",
      "rationale_en": "Night sweats reflect diurnal peaks in immune inflammatory mediator release during sleep cycles.",
      "rationale_tl": "Ang labis na pagpapawis sa gabi ay sanhi ng pabalik-balik na pagtaas ng temperatura habang natutulog.",
      "weight": 2,
      "is_cardinal": false,
      "icon": Icons.bedtime_outlined
    },
    {
      "category_en": "Chest & Pulmonary Indicators",
      "category_tl": "Sintomas sa Dibdib at Paghinga",
      "phase_num": 1,
      "q_en": "Do you experience chest tightness or pain when breathing deeply?",
      "q_tl": "May pananakit ka ba ng dibdib o hirap sa malalim na paghinga?",
      "desc_en": "Localized discomfort, dull pressure, or sharp aches exacerbated by coughing or deep inhalation.",
      "desc_tl": "Matulis o mabigat na sakit sa dibdib na lumalala kapag humihinga nang malalim o umuubo.",
      "rationale_en": "Pleuritic chest discomfort suggests peripheral lung inflammation, pleural friction, or strain from chronic coughing.",
      "rationale_tl": "Ang sakit sa dibdib ay maaaring senyales ng pamamaga sa pleura ng baga o puwersa mula sa matagal na pag-ubo.",
      "weight": 2,
      "is_cardinal": false,
      "icon": Icons.monitor_heart_outlined
    },
    {
      "category_en": "Constitutional Systemic Signs",
      "category_tl": "Pangkalahatang Sintomas sa Katawan",
      "phase_num": 1,
      "q_en": "Have you had unexplained chronic fatigue lasting several weeks?",
      "q_tl": "Nakakaramdam ka ba ng matinding panghihina na hindi nawawala?",
      "desc_en": "Profound, lingering exhaustion that does not resolve following adequate rest or sleep.",
      "desc_tl": "Walang tigil na pakiramdam ng pagod na hindi nawawala kahit nagpahinga nang maayos.",
      "rationale_en": "Persistent fatigue indicates chronic immune system activation against an ongoing intracellular pulmonary burden.",
      "rationale_tl": "Ang panghihina ay patunay ng patuloy na paggamit ng resistensya laban sa impeksyon.",
      "weight": 1,
      "is_cardinal": false,
      "icon": Icons.battery_alert_outlined
    },
    {
      "category_en": "Constitutional Systemic Signs",
      "category_tl": "Pangkalahatang Sintomas sa Katawan",
      "phase_num": 1,
      "q_en": "Do you have a recurring low-grade fever (especially afternoon)?",
      "q_tl": "Mayroon ka bang pabalik-balik na sinat o lagnat tuwing hapon?",
      "desc_en": "Mildly elevated body temperature that consistently peaks in the late afternoon or evening.",
      "desc_tl": "Bahagyang pagtaas ng temperatura na madalas mangyari sa hapon o gabi.",
      "rationale_en": "Low-grade diurnal fevers following a circadian cycle are a hallmark clinical characteristic of Tuberculosis.",
      "rationale_tl": "Ang pabalik-balik na lagnat sa hapon ay isa sa mga klasikong palatandaan ng tuberculosis.",
      "weight": 2,
      "is_cardinal": false,
      "icon": Icons.thermostat_outlined
    },
    {
      "category_en": "Constitutional Systemic Signs",
      "category_tl": "Pangkalahatang Sintomas sa Katawan",
      "phase_num": 1,
      "q_en": "Have you noticed a significant, prolonged loss of appetite?",
      "q_tl": "Nawalan ka ba ng gana sa pagkain nitong mga nakaraang linggo?",
      "desc_en": "A marked reduction in dietary intake and lack of hunger lasting more than a week.",
      "desc_tl": "Kakulangan ng ganang kumain na tumatagal ng higit sa isang linggo.",
      "rationale_en": "Anorexia is mediated by circulating inflammatory tumor necrosis factor produced during active infectious responses.",
      "rationale_tl": "Ang kawalan ng gana kumain ay sanhi ng mga protinang inilalabas ng katawan habang may impeksyon.",
      "weight": 1,
      "is_cardinal": false,
      "icon": Icons.restaurant_outlined
    },
    {
      "category_en": "Epidemiological Exposure & Contact",
      "category_tl": "Kasaysayan ng Pagkakalantad (Exposure)",
      "phase_num": 2,
      "q_en": "Have you lived with or cared for an individual with active TB?",
      "q_tl": "May kasama ka ba sa bahay o inalagaan na may aktibong TB?",
      "desc_en": "Prolonged, close indoor contact (household, workplace, caregiving) with a confirmed case.",
      "desc_tl": "Matagal at malapit na pakikisalamuha sa isang kilalang pasyenteng may Tuberculosis.",
      "rationale_en": "Household contacts carry an elevated 30-50% transmission risk via airborne droplet nuclei, requiring prophylactic contact tracing.",
      "rationale_tl": "Ang mga kasama sa bahay ay may mataas na banta na mahawahan sa hangin at kailangang maisama sa contact tracing.",
      "weight": 4,
      "is_cardinal": false,
      "icon": Icons.people_outline
    },
    {
      "category_en": "Clinical Vulnerabilities & Comorbidities",
      "category_tl": "Kalagayan ng Resistensya at Kalusugan",
      "phase_num": 3,
      "q_en": "Do you have an underlying immunocompromising condition?",
      "q_tl": "Mayroon ka bang kondisyon na nagpapahina sa iyong resistensya?",
      "desc_en": "Co-existing medical conditions such as Diabetes Mellitus, HIV, kidney disease, or immunosuppressive therapy.",
      "desc_tl": "Kondisyon tulad ng Diabetes, HIV, sakit sa bato, o umiinom ng gamot na nagpapababa ng resistensya.",
      "rationale_en": "Cell-mediated immune suppression drastically accelerates the progression from latent Mycobacterium infection to active contagious disease.",
      "rationale_tl": "Ang mahinang resistensya ay nagpapabilis sa pagkalat ng bacteria mula latent tungo sa aktibong TB.",
      "weight": 3,
      "is_cardinal": false,
      "icon": Icons.health_and_safety_outlined
    },
    {
      "category_en": "Epidemiological Exposure & Contact",
      "category_tl": "Kasaysayan ng Pagkakalantad (Exposure)",
      "phase_num": 2,
      "q_en": "Have you resided in or visited a high-burden TB community?",
      "q_tl": "Tumira o nagpunta ka ba sa lugar na may mataas na kaso ng TB?",
      "desc_en": "Extended presence in densely populated, poorly ventilated, or medically underserved environments.",
      "desc_tl": "Matagal na pananatili sa mga siksikan o hindi mahangahang lugar na may mataas na kaso ng TB.",
      "rationale_en": "High population density and inadequate ventilation multiply airborne transmission probabilities.",
      "rationale_tl": "Ang pananatili sa mga siksikang komunidad ay nagpapataas ng panganib na makalanghap ng bacteria.",
      "weight": 2,
      "is_cardinal": false,
      "icon": Icons.flight_takeoff_outlined
    },
    {
      "category_en": "Clinical Vulnerabilities & Comorbidities",
      "category_tl": "Kalagayan ng Resistensya at Kalusugan",
      "phase_num": 3,
      "q_en": "Do you currently smoke or have a history of heavy tobacco use?",
      "q_tl": "Naninigarilyo ka ba o may mahabang kasaysayan ng paninigarilyo?",
      "desc_en": "Daily cigarette, tobacco, or vape usage, or a multi-year history of chronic smoking.",
      "desc_tl": "Kasalukuyang naninigarilyo, nag-ve-vape, o may matagal na kasaysayan ng paninigarilyo.",
      "rationale_en": "Tobacco smoke paralyzes bronchial ciliary clearance and impairs alveolar macrophage phagocytosis, quadrupling TB susceptibility.",
      "rationale_tl": "Ang usok ng sigarilyo ay pumipinsala sa natural na pananggalang ng baga laban sa mikrobyo.",
      "weight": 1,
      "is_cardinal": false,
      "icon": Icons.smoking_rooms_outlined
    },
  ];

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
    flutterTts.stop();
    super.dispose();
  }

  // Read aloud function
  Future<void> _speakText(String title, String description) async {
    await flutterTts.stop();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borderNeutral),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined, color: primaryTeal, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clinical Triage Protocol',
                  style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            'This assessment follows the diagnostic screening protocol of the National Tuberculosis Control Program. Responses are forwarded to Carmona Health Center clinicians for verification.\n\nPlease evaluate your symptoms honestly.',
            style: GoogleFonts.inter(color: textMuted, fontSize: 13, height: 1.45),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: textMuted, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                'Begin Intake',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
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
    flutterTts.stop();
    if (userAnswers[currentIndex] == null) {
      setState(() => _showError = true);
      return;
    }

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        _showError = false;
        _showRationale = false;
      });
    } else {
      setState(() {
        _showSummary = true;
      });
    }
  }

  void _handlePrevious() {
    flutterTts.stop();
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _showError = false;
        _showRationale = false;
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
    } else if (isSymptomatic || isCloseContact || isVulnerable || finalScore >= 6) {
      finalRisk = "Medium Risk";
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'risk_level': finalRisk,
          'is_symptomatic': isSymptomatic,
          'is_close_contact': isCloseContact,
          'is_vulnerable': isVulnerable,
        }).eq('id', user.id);
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
      backgroundColor: backgroundSurface,
      body: _showSummary ? _buildSummaryView() : _buildQuestionView(),
    );
  }

  Widget _buildQuestionView() {
    final currentQ = questions[currentIndex];
    String qText = _isTagalog ? currentQ['q_tl'] : currentQ['q_en'];
    String descText = _isTagalog ? currentQ['desc_tl'] : currentQ['desc_en'];
    String categoryName = _isTagalog ? currentQ['category_tl'] : currentQ['category_en'];
    String rationaleText = _isTagalog ? currentQ['rationale_tl'] : currentQ['rationale_en'];
    IconData currentIcon = currentQ['icon'];
    int phaseNum = currentQ['phase_num'];
    bool isCardinal = currentQ['is_cardinal'] ?? false;
    String? currentAnswer = userAnswers[currentIndex];

    return Column(
      children: [
        // --- 1. CLINICAL HEADER & 3-PHASE TRIAGE STEPPER ---
        Container(
          padding: const EdgeInsets.fromLTRB(18, 48, 18, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDeep, primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    'Tuberculosis Clinical Triage',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  InkWell(
                    onTap: () {
                      flutterTts.stop();
                      setState(() => _isTagalog = !_isTagalog);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _isTagalog ? "TL" : "EN",
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3-Stage Clinical Protocol Bar
              Row(
                children: [
                  _buildPhaseStepPill(1, "1. Symptoms", phaseNum == 1, phaseNum > 1),
                  const SizedBox(width: 6),
                  _buildPhaseStepPill(2, "2. Exposure", phaseNum == 2, phaseNum > 2),
                  const SizedBox(width: 6),
                  _buildPhaseStepPill(3, "3. Health Profile", phaseNum == 3, false),
                ],
              ),
              const SizedBox(height: 12),

              // Linear Progress Line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${currentIndex + 1} of ${questions.length}",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "${((currentIndex + 1) / questions.length * 100).toInt()}% Evaluated",
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                  backgroundColor: Colors.white24,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        // --- 2. QUESTION INTAKE BODY ---
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey<int>(currentIndex),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Pill & Diagnostic Weight
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryTeal.withOpacity(0.2)),
                      ),
                      child: Text(
                        categoryName.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryTeal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCardinal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          "CARDINAL SIGN",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Question Header with TTS Speaker
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderNeutral),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCardinal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              currentIcon,
                              size: 22,
                              color: isCardinal ? const Color(0xFFDC2626) : primaryTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              qText,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textCharcoal,
                                height: 1.3,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, color: primaryTeal, size: 22),
                            onPressed: () => _speakText(qText, descText),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        descText,
                        style: GoogleFonts.inter(fontSize: 12.5, color: textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- 3. CLINICAL STATE DECISION CARDS ---
                Text(
                  _isTagalog ? "KUMPIRMASYON SA SINTOMAS" : "CLINICAL EVALUATION",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // Option: YES
                _buildClinicalDecisionCard(
                  value: "Yes",
                  title: _isTagalog ? "Oo — Nararanasan / Positibo" : "Yes — Present / Confirmed",
                  subtitle: _isTagalog ? "Aktibong nararanasan sa nakaraang mga linggo" : "Currently experiencing or positive history",
                  icon: Icons.check_circle_outline_rounded,
                  isSelected: currentAnswer == "Yes",
                  activeColor: isCardinal ? const Color(0xFFDC2626) : primaryTeal,
                  activeBg: isCardinal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDFA),
                ),
                const SizedBox(height: 10),

                // Option: NO
                _buildClinicalDecisionCard(
                  value: "No",
                  title: _isTagalog ? "Hindi — Wala / Negatibo" : "No — Absent / Denied",
                  subtitle: _isTagalog ? "Walang ganitong sintomas o kasaysayan" : "No manifestation or exposure observed",
                  icon: Icons.cancel_outlined,
                  isSelected: currentAnswer == "No",
                  activeColor: const Color(0xFF475569),
                  activeBg: const Color(0xFFF8FAFC),
                ),

                // Real-time Red-Flag or Presumptive Alert Banner
                if (currentAnswer == "Yes" && isCardinal) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentIndex == 1
                                ? "Critical Indicator: Hemoptysis is a primary pulmonary red flag. Clinical laboratory evaluation at Carmona Health Center will be recommended."
                                : "Presumptive TB Indicator: Cough lasting >= 2 weeks meets the clinical benchmark for confirmatory sputum testing.",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF991B1B),
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // --- 4. EXPANDABLE "WHY WE ASK THIS" ACCORDION ---
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showRationale = !_showRationale);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderNeutral),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: primaryTeal, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isTagalog
                                    ? "Bakit ito tinatanong ng Carmona Health Center?"
                                    : "Why Carmona Health Center screens for this",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryTeal,
                                ),
                              ),
                            ),
                            Icon(
                              _showRationale ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                        if (_showRationale) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: borderNeutral),
                          const SizedBox(height: 8),
                          Text(
                            rationaleText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF334155),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (_showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _isTagalog ? "Pumili ng pagsusuri bago magpatuloy." : "Please select an answer to continue.",
                          style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // --- 5. FIXED CLINICAL NAVIGATION FOOTER ---
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderNeutral)),
          ),
          child: Row(
            children: [
              if (currentIndex > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: borderNeutral, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handlePrevious,
                      child: Text(
                        _isTagalog ? "Bumalik" : "Previous",
                        style: GoogleFonts.inter(color: textCharcoal, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: currentIndex == 0 ? 2 : 1,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleNext,
                    child: Text(
                      currentIndex < questions.length - 1
                          ? (_isTagalog ? "Susunod na Tanong" : "Next Protocol")
                          : (_isTagalog ? "Suriin ang Sagot" : "Review Intake"),
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- REFINED STEP PILL ---
  Widget _buildPhaseStepPill(int phase, String label, bool isActive, bool isPast) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : (isPast ? Colors.white.withOpacity(0.2) : Colors.black12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? primaryDark : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  // --- INTERACTIVE CLINICAL STATE CARD ---
  Widget _buildClinicalDecisionCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          userAnswers[currentIndex] = value;
          _showError = false;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : borderNeutral,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.03 : 0.01),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? activeColor : textMuted.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? textCharcoal : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isSelected ? activeColor.withOpacity(0.85) : textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUMMARY REVIEW SCREEN ---
  Widget _buildSummaryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 48, 18, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryDeep, primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => setState(() => _showSummary = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _isTagalog ? 'Suriin ang mga Sagot' : 'Review Triage Responses',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => setState(() => _isTagalog = !_isTagalog),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _isTagalog ? "TL" : "EN",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              String qText = _isTagalog ? questions[index]['q_tl'] : questions[index]['q_en'];
              String answer = userAnswers[index] ?? "N/A";
              String displayAnswer = answer == "Yes" ? (_isTagalog ? "Oo (Positibo)" : "Yes (Present)") : (_isTagalog ? "Hindi (Negatibo)" : "No (Denied)");
              IconData rowIcon = questions[index]['icon'];
              bool isYes = answer == "Yes";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderNeutral),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isYes ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(rowIcon, color: isYes ? const Color(0xFFDC2626) : primaryTeal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Q${index + 1}: $qText",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textCharcoal, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isYes ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              displayAnswer,
                              style: GoogleFonts.inter(
                                color: isYes ? const Color(0xFF991B1B) : const Color(0xFF334155),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: textMuted, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _showSummary = false;
                          currentIndex = index;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderNeutral)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: _calculateAndNavigate,
              child: Text(
                _isTagalog ? "Isumite ang Pagsusuri" : "Submit Triage Protocol",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}