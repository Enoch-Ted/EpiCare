# EpiCare: A Real-Time Mobile Skin Cancer Detection Application

EpiCare is an offline-capable Android mobile application that performs real-time, on-device screening of skin lesions for early signs of skin cancer. Designed for accessibility and privacy, it enables users to capture or upload lesion images and receive immediate classification feedback using a hybrid CNN-ViT deep learning model. EpiCare is optimized for Android smartphones with at least 4GB RAM and mid-range GPU capabilities.

---

##  Features

- 👤 Multiple user profiles with optional biometric/PIN security
- 🗺️ Interactive body map for lesion tracking
- 📸 Image capture or upload functionality
- 🧠 Lesion detection using YOLOv8 
- 🔬 Lesion classification using a TFLite-optimized CNN-ViT model
- 📊 Classification output with confidence score and color-coded risk indication
- 🔌 Fully offline functionality (no internet needed)
- 🧾 Scan history with timestamps
- 📤 Shareable PDF scan report generation

---

##  AI Model Overview

- **YOLOv8**: Detects lesion location in the input image (external/integrated upstream)
- **Hybrid CNN-ViT Classifier**:
    - CNN: VGG16 for local spatial feature extraction
    - ViT: Transformer encoders for long-range context modeling
    - Output: Binary classification (`Benign` / `Malignant`) with confidence score
- Format: Quantized FP16 TensorFlow Lite model (`cnn_vit_model.tflite`)

---

##  Tech Stack

- **Frontend**: Flutter (Dart)
- **Machine Learning**: TensorFlow, Keras
- **Model Deployment**: TensorFlow Lite (TFLite)
- **Database**: SQLite (using `sqflite` plugin)
- **IDE**: Android Studio, Google Colab, VS Code

---

## ⚙️ Installation Instructions

1. **Clone this repository:**

```bash
git clone https://github.com/Enoch-Ted/EpiCare.git
cd EpiCare
```

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Add the TFLite model:**

Place your `.tflite` model and `labels.txt` file in the `/models` and `/assets` folder.

4. **Run the app on a connected device:**

```bash
flutter run
```

---

## 📸 Screenshots

### Profile Creation
![Profile Screen](screenshots/User%20Profile%20Creation.png)

### Overall AppView
![My_Body](screenshots/Initial%20Landing%20page%20after%20logging%20in.png)

### Lesion Marking placement on Body Map in the Camera Tab
![Body Map_Camera](screenshots/Camera%20Tab%20zoomed%20top%20pace%20the%20mark%20accurately.png)

### Scan Result Output
![Scan Result](screenshots/results%20screen.png)

### Report Generated Output
![Report Result](screenshots/Report%20Generated.png)

### History View
![History](screenshots/History%20Tab.png)

### Lesion Marking on Body Map after several scans
![Body Map](screenshots/My%20body%20after%20several%20scans.png)

---
## 📈 Testing & Performance

- ✅ Accuracy: **81.1%**
- ✅ AUC Score: **0.901**
- ⚡ On-device inference time: **< 3 seconds**
- 📱 Optimized for Android (≥4GB RAM)

---

## 👤 Author

**Enoch Teddy**  

---

## 📃 License

This project is licensed under the **MIT License**.  
Feel free to use, modify, and distribute with attribution.
