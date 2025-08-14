<div class="container">
  <div class="header">
      <h1>OCR Text Recognition App 📱✨</h1>
      <p>An intelligent iOS application that converts images to text using advanced OCR technology combined with custom AI-powered text correction.</p>
            
  <div class="badges">
      <span class="badge">iOS 15.0+</span>
      <span class="badge">Swift 5.5+</span>
      <span class="badge">Xcode 14.0+</span>
      <span class="badge">Mistral AI OCR</span>
      <span class="badge">AI Powered</span>
  </div>
</div>

  <h2>📋 Overview</h2>
  <p>This Final Year Project demonstrates the integration of Optical Character Recognition (OCR) with custom AI models to provide accurate text extraction and correction from images. The app offers multiple input methods and export formats, making document digitization seamless and efficient.</p>

  <h2>✨ Features</h2>
  
  <div class="feature-grid">
      <div class="feature-card">
          <h3>🎯 Core Functionality</h3>
          <ul>
              <li>📸 <strong>Camera Scanning</strong> - Capture documents directly using device camera</li>
              <li>🖼️ <strong>Gallery Selection</strong> - Import images from photo library</li>
              <li>📄 <strong>PDF Processing</strong> - Extract text from PDF documents</li>
              <li>🤖 <strong>AI-Powered OCR</strong> - Advanced text recognition using Apple Vision Framework</li>
              <li>✏️ <strong>Custom Text Correction</strong> - Proprietary AI model for word and sentence correction</li>
              <li>📱 <strong>Multi-Format Export</strong> - Save as PDF, WORD, DOCS, ODT, TXT formats</li>
          </ul>
      </div>
      
  <div class="feature-card">
      <h3>👤 User Management</h3>
      <ul>
          <li>🔐 <strong>Secure Authentication</strong> - Firebase-powered user accounts</li>
          <li>☁️ <strong>Cloud Sync</strong> - Cross-device document synchronization</li>
          <li>📚 <strong>Processing History</strong> - Track and manage all processed documents</li>
          <li>💾 <strong>Saved Files</strong> - Organize and access exported documents</li>
          <li>⚙️ <strong>User Settings</strong> - Customizable preferences and profile management</li>
      </ul>
  </div>
  </div>

  <h2>🛠️ Technology Stack</h2>
  
  <div class="tech-stack">
      <div class="tech-category">
          <h4>Frontend</h4>
          <ul>
              <li>Swift & SwiftUI - Modern iOS development</li>
              <li>UIKit - Camera and system integration</li>
              <li>Core Data - Local data persistence</li>
          </ul>
      </div>
      
  <div class="tech-category">
      <h4>Backend & Services</h4>
      <ul>
          <li>Firebase Authentication - User management</li>
          <li>Firebase Firestore - Cloud database</li>
          <li>Firebase Storage - File storage and sync</li>
          <li>Mistral AI OCR - Built-in OCR capabilities</li>
      </ul>
  </div>
  
  <div class="tech-category">
      <h4>AI & Machine Learning</h4>
      <ul>
          <li>Custom Text Correction Model - Proprietary AI for text enhancement</li>
          <li>Core ML - On-device model inference</li>
          <li>Vision Framework - Text recognition and processing</li>
      </ul>
  </div>
  </div>

  <h2>🏗️ Architecture</h2>
  <div class="architecture">
      📱 iOS App (SwiftUI)<br>
      ├── 🔐 Authentication Layer (Firebase Auth)<br>
      ├── 📸 Input Processing (Camera/Gallery/PDF)<br>
      ├── 🤖 OCR Engine (Mistral AI OCR)<br>
      ├── ✨ AI Text Correction (Custom Model)<br>
      ├── 💾 Export Engine (Multiple Formats)<br>
      ├── ☁️ Cloud Storage (Firebase)<br>
      └── 📊 Data Management (Core Data + Firestore)<br>
  </div>

  <h2>🚀 Getting Started</h2>
  
  <h3>Prerequisites</h3>
  <ul>
      <li>Xcode 14.0+</li>
      <li>iOS 15.0+</li>
      <li>Apple Developer Account</li>
      <li>Firebase Project</li>
  </ul>

  <h3>Installation</h3>
  
  <p><strong>1. Clone the repository</strong></p>
  <div class="code-block">
git clone https://github.com/MdSourav76046/OCR-Ai_ProjectFinalYear.git
cd ocr-text-recognition-app
        </div>

  <p><strong>2. Open the project in Xcode</strong></p>
  <div class="code-block">
open OCRApp.xcodeproj
        </div>

<p><strong>3. Configure Firebase</strong></p>
<ul>
  <li>Add your <code>GoogleService-Info.plist</code> to the project</li>
  <li>Update Bundle Identifier to match your Firebase configuration</li>
</ul>

<p><strong>4. Build and run</strong></p>
<ul>
  <li>Select your target device/simulator</li>
  <li>Press <code>Cmd + R</code> to build and run</li>
</ul>

<h2>📱 App Flow</h2>
<div class="app-flow">
  🔑 Authentication → 📱 Main Dashboard → 📸 Capture/Select → 
  🤖 OCR Processing → ✨ AI Correction → 📝 Format Selection → 
  💾 Export/Save → 📚 History Management
</div>

<h2>🎯 Key Screens</h2>
<table>
  <thead>
      <tr>
          <th>Screen</th>
          <th>Description</th>
      </tr>
  </thead>
  <tbody>
      <tr>
          <td><strong>Sign Up/In</strong></td>
          <td>User authentication with email/password and social login</td>
      </tr>
      <tr>
          <td><strong>Main Dashboard</strong></td>
          <td>Three input options: Camera, Gallery, PDF</td>
      </tr>
      <tr>
          <td><strong>Camera View</strong></td>
          <td>Document scanning with real-time preview</td>
      </tr>
      <tr>
          <td><strong>Processing</strong></td>
          <td>OCR extraction and AI correction pipeline</td>
      </tr>
      <tr>
          <td><strong>Format Selection</strong></td>
          <td>Choose output format (PDF, WORD, TXT, etc.)</td>
      </tr>
      <tr>
          <td><strong>History</strong></td>
          <td>View and manage processed documents</td>
      </tr>
      <tr>
          <td><strong>Settings</strong></td>
          <td>User profile and app preferences</td>
      </tr>
  </tbody>
</table>

<h2>🧠 AI Integration</h2>
<div class="highlight-box">
  <p><strong>The app features a two-stage AI pipeline:</strong></p>
  <ul>
      <li><strong>Stage 1:</strong> Text Extraction using Apple Vision Framework</li>
      <li><strong>Stage 2:</strong> Custom AI model for text correction and enhancement</li>
  </ul>
  
  <p><strong>This approach significantly improves accuracy by:</strong></p>
  <ul>
      <li>✅ Correcting common OCR errors</li>
      <li>✅ Fixing spelling and grammar mistakes</li>
      <li>✅ Enhancing sentence structure</li>
      <li>✅ Providing contextual corrections</li>
  </ul>
</div>

<h2>📊 Technical Highlights</h2>
<ul>
  <li>🤖 <strong>Custom AI Model Integration</strong> for text correction</li>
  <li>🔄 <strong>Multi-stage processing pipeline</strong> (OCR → AI → Export)</li>
  <li>☁️ <strong>Cross-platform cloud synchronization</strong></li>
  <li>📁 <strong>Multiple export format support</strong></li>
  <li>📸 <strong>Real-time document scanning</strong></li>
  <li>📱 <strong>Offline-capable processing</strong></li>
</ul>

<h2>🔒 Privacy & Security</h2>
<div class="security-features">
  <div class="security-item">
      <strong>🏠 Local Processing: </strong> OCR and AI correction performed on-device
  </div>
  <div class="security-item">
      <strong>🔐 Secure Authentication: </strong> Firebase Auth with industry standards
  </div>
  <div class="security-item">
      <strong>🛡️ Data Encryption: </strong> All cloud data encrypted in transit and at rest
  </div>
  <div class="security-item">
      <strong>👤 User Control: </strong> Complete control over data retention and deletion
  </div>
</div>

<h2>🤝 Contributing</h2>
<p>This is an academic project, but suggestions and feedback are welcome:</p>
<ol>
  <li>Fork the repository</li>
  <li>Create a feature branch</li>
  <li>Submit a pull request with detailed description</li>
</ol>

<div class="contact-section">
  <h2>📞 Contact</h2>
  <p><strong>Developer:</strong> Md Sourav<br>
  <strong>Email:</strong> mdsourav76046@gmail.com<br>
  <strong>Institution:</strong> Rajshahi University<br>
  <strong>Project Year:</strong> 2025</p>
</div>

<h2>🙏 Acknowledgments</h2>
<ul>
  <li>Rajshahi University Computer Science Department</li>
  <li>Firebase for backend infrastructure</li>
  <li>Apple Vision Framework team</li>
  <li>Open source iOS development community</li>
</ul>

<div class="footer">
  <button class="star-button">⭐ Star this repository if you found it helpful!</button>
  <br><br>
  <div class="badges">
      <span class="badge">iOS App</span>
      <span class="badge">OCR Technology</span>
      <span class="badge">AI Powered</span>
      <span class="badge">Academic Project</span>
  </div>
</div>
</div>
