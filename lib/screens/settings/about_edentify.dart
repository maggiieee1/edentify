import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutEdentifyScreen extends StatelessWidget {
  const AboutEdentifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'About Edentify',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Logo / Header
            Center(
              child: Column(
                children: [
                  const Icon(Icons.healing, size: 80, color: Color(0xFF008080)),
                  const SizedBox(height: 12),
                  Text(
                    "Edentify",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF008080),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Edema Detection and Monitoring System",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// Overview
            Text(
              "Overview",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Edentify is a mobile and web-based system designed to assist in the early detection and continuous monitoring of edema severity among dialysis patients. "
              "The system utilizes computer vision and machine learning models to classify the level of foot swelling into four categories: Normal, Mild, Moderate, and Severe.",
              style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 25),

            /// Purpose
            Text(
              "Purpose and Objectives",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "The main goal of Edentify is to provide an accessible, non-invasive, and real-time monitoring tool for both patients and healthcare providers. "
              "Through regular image scanning and data tracking, the system aims to support doctors in making timely decisions and to help patients stay aware of their condition.",
              style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 25),

            /// Impact
            Text(
              "Impact and Significance",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Edentify bridges the gap between patients and healthcare professionals by promoting proactive health monitoring. "
              "It aims to reduce risks associated with untreated fluid retention, improve clinical response times, and encourage patients to be more engaged with their health.",
              style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 25),

            /// Team
            Text(
              "Developed By",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "A student research team dedicated to support medical systems. "
              "The Edentify project serves as their undergraduate thesis, representing the practical application of Computer Vision in healthcare.",
              style: GoogleFonts.poppins(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 25),

            /// Footer
            Center(
              child: Column(
                children: [
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 10),
                  Text(
                    "© 2025 Edentify Project Team\nAll rights reserved.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
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
}
