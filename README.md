# 📚 Kaksha: Revolutionizing Classroom Management 📚

**Effortlessly Manage Classes and Reduce Teachers Workload**

<div align="center">
  <img src="https://i.imgur.com/CZvbxMW.png" alt="Kaksha Logo" width="310">
</div>

## 🚀 Overview

Kaksha is an all-in-one classroom management solution designed to significantly reduce the administrative workload for teachers while providing a seamless and engaging educational experience for students. The name "Kaksha" (कक्षा) means "classroom" in Hindi, embodying our mission to transform traditional classrooms into smart, efficient, and interactive learning environments, aligning with **UN SDG - 4 Quality Education.**

In today's fast-paced world, educators are burdened with numerous tasks ranging from managing assignments and attendance to providing personalized feedback. Kaksha addresses these challenges by integrating advanced technologies like AI, Bluetooth-based attendance systems, and automated grading, making teaching more focused, efficient, and less stressful.


## ✨ Key Features

### 🏫 Class Management
- **Intuitive Class Creation**: Teachers can create unlimited virtual classrooms with customizable settings
- **Secure Enrollment System**: Students join via unique class codes or direct invitations
- **Comprehensive Dashboard**: Bird's-eye view of all class activities, assignments, and student engagement metrics
- **Student Directory**: Detailed profiles with performance analytics and engagement history

### 📋 Assignments
- **Upload and Submit Assignments**: Teachers can upload assignments with due dates, and students can submit their work directly through the app
- **Automated Grading with AI**:
  - Instant evaluation using Google Vision API and Gemini Models with a single click
  - Our own **Fine Tuned Gemini Model** is trained to give detailed feedback and preliminary scores based on content quality and relevance
  - Editable scores for teacher review before publishing
  - Comprehensive feedback for students to identify areas for improvement
### ❓ Quizzes
- **AI-Powered Question Generation**: Create quizzes manually or use Gemini Models for auto-generated questions.
- **Smart Scheduling**: Set start/end dates, duration limits, and auto-lock quizzes after deadlines.
- **Cheating Prevention**: Detect tab switches, external cameras, and unauthorized devices using AI.
- **Instant Grading & Feedback**: Auto-score objective questions; AI evaluates short answers with detailed feedback.
- **Quiz Analytics**: Track student performance, accuracy rates, and identify knowledge gaps.

### 🤖 Phone Detection & Anti-Cheating Model
-  Live object detection using **YOLOv11n** to monitor student activity during quizzes.
-  Instant alerts when a mobile phone is detected on screen.
-  **Web Dashboard Alert System**: Connected to a Flask-based web dashboard with Socket.IO
Alerts are displayed live on the interface whenever a phone is detected
Ideal for supervisors and teachers to monitor multiple students efficiently
### 🗣️ Class Chat
- **Real-time Communication**: Collaborative environment for teachers and students to interact and clarify doubts

### 📅 Smart Attendance System
- **Bluetooth-based Attendance**:
  - Automated attendance marking using Bluetooth technology
  - Eliminates manual roll calls and saves valuable class time
- **Attendance Analytics**:
  - Detailed historical attendance reports with date filtering

### 🤖 AI-Powered Tools
- **PDF Generator**:
  - Create comprehensive study materials on any topic with a simple prompt
  - Well-structured and easy-to-understand content for better learning
- **Question Paper Generator**:
  - Specify topic, description, number of questions, and marks distribution
  - Generate balanced assessments across different difficulty levels
  - Significantly reduce time spent on exam preparation

## 📱 Application Showcase

### Teacher Interface
<div align="center">
  <table>
    <tr>
      <td align="center">
        <img src="https://imgur.com/wjxaanc.gif" alt="Class Features" width="250"><br>
        <b>Class Features</b>
      </td>
     <td align="center">
        <img src="https://imgur.com/uKiF7kG.gif" alt="Student Class View" width="250"><br>
        <b>Take Attendance</b>
      </td>
       <td align="center">
        <img src="https://imgur.com/n3BujsJ.gif" alt="Pdf and question paper generation" width="250"><br>
        <b>Pdf and question paper generation</b>
      </td>
    </tr>
  </table>
</div>
<br>

### Student Interface
<div align="center">
  <table>
    <tr>
       <td align="center">
        <img src="https://imgur.com/g03z0Jf.gif" alt="Give Attendance" width="250"><br>
        <b>Give Attendance</b>
      </td>
       <td align="center">
        <img src="https://imgur.com/fQLFPdy.gif" alt="Submit Assignment" width="250"><br>
        <b>Submit Assignment</b>
      </td>
    </tr>
  </table>
</div>
<br>


## 🛠️ Tech Stack
- **Frontend**: Flutter, Dart
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **APIs**:
  - Google Vision API for OCR and analysis
  - Gemini API for assignment grading and insights
- **Bluetooth Integration**: Flutter Blue package for attendance
- **Ultralytics YOLOv11n:** Real-time object detection
- **Torch:** Deep learning framework powering YOLO models

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- VS Code or Android Studio
- Dart and Flutter extensions for your IDE
- Android emulator or physical device

### Installation

1. Clone the repository:
  ```bash
    git clone https://github.com/shreeyagarg18/kaksha_hackathon.git
  ```
2. Navigate to the project directory:
  ```bash
    cd Kaksha
  ```
3. Install dependencies:
  ```bash
    flutter pub get
  ```
4. Run the application:
  ```bash
    flutter run
  ```
<hr>

### 👥 Team
1. Laksh R Jain      : [LinkedIn](https://www.linkedin.com/in/laksh-jain-6b308323b/)
2. Atman Pattanaik   : [LinkedIn](https://www.linkedin.com/in/atman-pattanaik-558b06285/)
3. Anushri Maheswari : [LinkedIn](https://www.linkedin.com/in/anushri-maheshwari-453049285/)
4. Shreeya Garg      : [LinkedIn](https://www.linkedin.com/in/shreeyag/)

<hr>

## 🪪 License

Kaksha is licensed under the MIT license. See [LICENSE](LICENSE) for more information.

--- 

<div align="center">
  <p>Made with ❤️ by Team Kaksha</p>
</div>

  
