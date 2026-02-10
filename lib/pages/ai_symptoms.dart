import 'package:flutter/material.dart';
import 'package:medical/models/symptom.dart';
import 'ai_diagnosis.dart';
import '../services/doctor_service.dart';
import 'nearby_doctors.dart';

class AISymptomsPage extends StatefulWidget {
  const AISymptomsPage({super.key});

  @override
  State<AISymptomsPage> createState() => _AISymptomsPageState();
}

class _AISymptomsPageState extends State<AISymptomsPage> {
  List<SymptomModel> symptoms = SymptomModel.getCommonSymptoms();
  int selectedAge = 25;
  String selectedGender = 'Male';
  TextEditingController additionalInfoController = TextEditingController();
  Map<String, String> symptomSeverity = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SwasthMitra AI Assistant',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Select Your Symptoms',
                _buildSymptomsGrid(),
              ),
              const SizedBox(height: 20),
              _buildSection(
                'Personal Information',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAgeSlider(),
                    const SizedBox(height: 16),
                    _buildGenderSelector(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSection(
                'Additional Information',
                TextField(
                  controller: additionalInfoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any other symptoms or medical history?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffE8E8E8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffE8E8E8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xff51A8FF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildAnalyzeButton(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final service = DoctorService();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NearbyDoctorsPage(service: service),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Find Nearby Doctors'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSymptomsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((symptom) {
        return GestureDetector(
          onTap: () {
            setState(() {
              symptom.isSelected = !symptom.isSelected;
              if (symptom.isSelected) {
                symptomSeverity[symptom.name] = 'moderate';
              } else {
                symptomSeverity.remove(symptom.name);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: symptom.isSelected ? const Color(0xff51A8FF) : Colors.white,
              border: Border.all(
                color: symptom.isSelected ? const Color(0xff51A8FF) : const Color(0xffE8E8E8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              symptom.name,
              style: TextStyle(
                color: symptom.isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age: $selectedAge years',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: selectedAge.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xff51A8FF),
          onChanged: (value) {
            setState(() {
              selectedAge = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Male', 'Female', 'Other'].map((gender) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedGender = gender;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selectedGender == gender
                        ? const Color(0xff51A8FF)
                        : Colors.white,
                    border: Border.all(
                      color: selectedGender == gender
                          ? const Color(0xff51A8FF)
                          : const Color(0xffE8E8E8),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    gender,
                    style: TextStyle(
                      color: selectedGender == gender
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final selectedSymptoms = symptoms
        .where((s) => s.isSelected)
        .map((s) => s.name)
        .toList();
    final isEnabled = selectedSymptoms.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIDiagnosisPage(
                      symptoms: selectedSymptoms,
                      age: selectedAge,
                      gender: selectedGender,
                      additionalInfo: additionalInfoController.text,
                      symptomSeverity: symptomSeverity,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff51A8FF),
          disabledBackgroundColor: const Color(0xff51A8FF).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isEnabled
              ? 'Analyze Symptoms (${selectedSymptoms.length})'
              : 'Select at least one symptom',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    additionalInfoController.dispose();
    super.dispose();
  }
}
