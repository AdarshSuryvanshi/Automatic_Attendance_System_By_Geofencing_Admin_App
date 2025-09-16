# Automatic Attendance System by Geofencing - Admin App

A Flutter-based admin application for managing automatic attendance tracking using geofencing technology. This app allows administrators to monitor, manage, and track employee/student attendance based on their geographical location.

## 🚀 Features

### Admin Dashboard
- **Real-time Attendance Monitoring**: View live attendance data of all users
- **Geofence Management**: Create, edit, and delete virtual boundaries for attendance tracking
- **User Management**: Add, remove, and manage user accounts
- **Attendance Reports**: Generate detailed attendance reports with filtering options
- **Location Tracking**: Monitor user locations and attendance patterns
- **Analytics Dashboard**: Visual representation of attendance data with charts and graphs

### Geofencing Capabilities
- **Virtual Boundaries**: Set up multiple geofenced areas for different locations
- **Automatic Check-in/Check-out**: Users are automatically marked present when entering designated areas
- **Radius Configuration**: Customizable geofence radius for different locations
- **Location Accuracy**: High-precision GPS tracking for accurate attendance marking
- **Offline Support**: Queue attendance data when offline and sync when connected

### Reporting & Analytics
- **Attendance Summary**: Daily, weekly, and monthly attendance summaries
- **Export Data**: Export attendance data to CSV/Excel formats
- **Visual Charts**: Interactive charts showing attendance trends
- **Individual Reports**: Generate reports for specific users or time periods
- **Late Arrival Tracking**: Monitor and report late arrivals and early departures

## 📱 Screenshots

<!-- Add your app screenshots here -->
*Screenshots will be added soon*

## 🛠️ Technologies Used

- **Frontend**: Flutter (Dart)
- **Database**: Firebase Firestore / SQLite
- **Authentication**: Firebase Authentication
- **Maps & Location**: Google Maps API, Geolocator
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **State Management**: Provider / Bloc (specify which one you used)
- **Charts**: FL Chart / Charts Flutter

## 📋 Prerequisites

Before running this application, make sure you have:

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase project setup (if using Firebase)
- Google Maps API key
- Android/iOS development environment

## 🚀 Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/AdarshSuryvanshi/Automatic_Attendance_System_By_Geofencing_Admin_App.git
   cd Automatic_Attendance_System_By_Geofencing_Admin_App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (if applicable)
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, and Cloud Messaging in Firebase Console

4. **Configure Google Maps**
   - Add your Google Maps API key in `android/app/src/main/AndroidManifest.xml`
   - Add API key in `ios/Runner/AppDelegate.swift`

5. **Run the application**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Environment Setup
Create a `.env` file in the root directory and add:
```
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### Permissions Required
- Location permissions (GPS)
- Internet access
- Storage permissions (for reports)
- Camera permissions (if QR code scanning is included)

## 📚 Usage

### For Administrators
1. **Login**: Use admin credentials to access the dashboard
2. **Setup Geofences**: Define geographical boundaries for attendance tracking
3. **Manage Users**: Add employees/students to the system
4. **Monitor Attendance**: View real-time attendance data
5. **Generate Reports**: Create and export attendance reports

### Key Functionalities
- **Dashboard**: Overview of today's attendance and key metrics
- **User Management**: Add/edit/delete user profiles
- **Geofence Management**: Create virtual boundaries with custom radius
- **Reports**: Generate various attendance reports
- **Settings**: Configure app preferences and notification settings

## 🏗️ Project Structure

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── attendance_model.dart
│   └── geofence_model.dart
├── screens/
│   ├── dashboard/
│   ├── user_management/
│   ├── geofence_management/
│   ├── reports/
│   └── settings/
├── services/
│   ├── auth_service.dart
│   ├── location_service.dart
│   ├── database_service.dart
│   └── notification_service.dart
├── widgets/
│   ├── common/
│   └── custom/
└── utils/
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [Student Attendance App](link-to-student-app) - Mobile app for students/employees
- [Web Dashboard](link-to-web-dashboard) - Web-based admin panel

## 📞 Support

If you have any questions or need help with the project, please:
- Open an issue on GitHub
- Contact: [your-email@example.com]

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Maps for location services
- All contributors who helped improve this project

---

**⭐ Star this repository if you found it helpful!**

**🔄 Fork this repository to contribute to the project!**

## 📈 Future Enhancements

- [ ] Face recognition integration
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Advanced analytics with AI insights
- [ ] Integration with HR management systems
- [ ] Biometric authentication
- [ ] Advanced reporting with custom templates

---

*Made with ❤️ using Flutter*
