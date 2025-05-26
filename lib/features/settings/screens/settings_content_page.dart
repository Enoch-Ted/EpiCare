// lib/features/settings/screens/settings_content_page.dart
import 'package:flutter/material.dart';

class SettingsContentPage extends StatelessWidget {
  final String title;

  // TODO: Add storage for the actual content.
  // You could pass content as a String, or have a map here
  // that looks up content based on the title.
  // Example: Map<String, String> staticContent = { ... };

  const SettingsContentPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  // TODO: Implement content lookup based on the title.
  String _getContentForTitle(String title) {
    // This is where you add the actual text for each page.
    // You can use if/else if, a switch statement, or a Map lookup.
    switch (title) {
      case 'FAQ':
        return '''
**Frequently Asked Questions**

Q: How do I use the app?
A: Go to the Body Scan screen, select a body part, mark a spot, and take a picture.

Q: What is a suspicious mole?
A: Moles that change size, shape, color, or have irregular borders or symptoms like itching or bleeding. Always consult a doctor if concerned.

Q: Is this app a substitute for professional medical advice?
A: NO. This app is for tracking purposes and educational information only. It does NOT provide medical diagnosis or advice. Always see a qualified healthcare professional for any health concerns.

// Add more questions and answers here
''';
      case 'Instructions for Use':
        return '''
**Instructions for Use**

1.  **Create Profile:** Start by creating a user profile. You can add multiple profiles if needed.
2.  **Navigate to Body Scan:** Use the bottom navigation bar to go to the "Body" screen.
3.  **Select Body Part:** Tap on the body outline to select the front or back view.
4.  **Add a Spot:** Tap the '+' button or tap directly on the body image to add a new spot.
5.  **Position Marker:** Drag the marker to the exact location of the spot you want to track.
6.  **Take a Photo:** Tap the camera icon to take a photo of the spot. Ensure good lighting and focus.
7.  **Save Scan:** Review the photo and location, then save the scan.
8.  **Track Changes:** Over time, add new scans for the same spot by finding it in the History and tapping "Add New Scan". Compare photos to monitor changes.
9.  **Review History:** The History tab shows all your recorded scans. Filter by profile or body part.

// Add more detailed instructions as needed
''';
      case 'Privacy Policy':
        return '''
**Privacy Policy**

Your privacy is important to us. This app collects and stores scan data locally on your device or securely in your chosen cloud backup service if enabled.

-   **Data Collected:** Photos of skin spots, associated metadata (date, location on body, user notes).
-   **How Data is Used:** Data is used solely for your personal tracking and monitoring within the app.
-   **Data Sharing:** We do NOT share your personal health data with any third parties.
-   **Data Storage:** Data is stored securely. You are responsible for managing backups.
-   **Deletion:** You can delete your profile and all associated data from the settings screen.

// Add full privacy policy text here
''';
      case 'Terms and Conditions':
        return '''
**Terms and Conditions**

By using this app, you agree to these terms.

1.  **Acceptance:** Use of the app constitutes acceptance of these terms.
2.  **Medical Disclaimer:** This app is NOT a medical device and does NOT provide medical diagnosis, treatment, or advice. Always consult a healthcare professional for health concerns.
3.  **Accuracy:** While we strive for accuracy, the information provided is for educational purposes only.
4.  **User Responsibility:** You are responsible for how you use the information and features of the app.
5.  **Intellectual Property:** The app content and features are protected by copyright.
6.  **Limitation of Liability:** We are not liable for any damages arising from the use or inability to use the app.

// Add full terms and conditions text here
''';
      case 'Disclaimer':
        return '''
**Disclaimer**

This app is intended for informational and tracking purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. Never disregard professional medical advice or delay in seeking it because of something you have read or seen in this app.

Reliance on any information provided by this app is solely at your own risk. The app developers are not responsible for any outcomes related to the use of this app.

// Add full disclaimer text here
''';

    // Add cases for all Skin Cancer Info sub-topics
      case 'Basal Cell Carcinoma':
        return '''
**Basal Cell Carcinoma (BCC)**

-   Most common type of skin cancer.
-   Often looks like a pearly or waxy bump, a flat flesh-colored or brown scar-like lesion, or a bleeding or scabbing sore that heals and then returns.
-   Usually grows slowly and rarely spreads to other parts of the body.
-   Caused by long-term exposure to UV radiation.
-   Commonly found on sun-exposed areas like the face, neck, and ears.

// Add more detailed info about BCC
''';
      case 'Squamous Cell Carcinoma':
        return '''
**Squamous Cell Carcinoma (SCC)**

-   Second most common type of skin cancer.
-   Often looks like a firm, red nodule, or a flat lesion with a scaly, crusted surface.
-   Can occur on any part of the body, but most common on sun-exposed areas like the face, lips, ears, hands, and arms.
-   Can sometimes grow quickly and spread, though less commonly than melanoma.
-   Also caused by long-term UV exposure.

// Add more detailed info about SCC
''';
      case 'Melanoma':
        return '''
**Melanoma**

-   Less common but the most serious type of skin cancer.
-   Develops in the cells that produce melanin (melanocytes).
-   Can occur anywhere on the body, including areas not exposed to the sun.
-   Often looks like a mole that changes in size, shape, color, or texture, or a new, unusual-looking growth.
-   The ABCDE rule can help identify potential melanoma:
    -   **A**symmetry
    -   **B**order irregularity
    -   **C**olor variation
    -   **D**iameter (larger than 6mm)
    -   **E**volving (changing over time)
-   Can spread aggressively if not caught early.

// Add more detailed info about Melanoma
''';
      case 'Symptoms of Suspicious Moles':
        return '''
**Symptoms of Suspicious Moles**

Look for changes in moles using the ABCDE rule:

-   **A**symmetry: One half does not match the other half.
-   **B**order: Edges are irregular, ragged, notched, or blurred.
-   **C**olor: The color is not the same all over or has shades of brown, black, pink, red, white, or blue.
-   **D**iameter: The spot is larger than 6 millimeters (about the size of a pencil eraser), although melanomas can be smaller.
-   **E**volving: The mole is changing in size, shape, color, or elevation, or new symptoms like itching, bleeding, or tenderness occur.

Any mole that looks different from your other moles (the "ugly duckling" sign) should also be checked.

// Add more details about symptoms
''';

    // Add cases for all SKINSPOTS sub-topics
      case 'Actinic Keratosis':
        return '''
**Actinic Keratosis (AK)**

-   Precancerous scaly or crusty growths caused by sun damage.
-   Often appear on sun-exposed areas like the face, scalp, ears, hands, and arms.
-   They are a warning sign of sun damage and can develop into squamous cell carcinoma if not treated.
-   Usually feel rough, like sandpaper.

// Add more info about AK
''';
    // Add cases for all SKIN CONDITIONS sub-topics


      default:
        return 'Content not found for "$title".'; // Fallback text
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get the content based on the title
    final String content = _getContentForTitle(title);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}