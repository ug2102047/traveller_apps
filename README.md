# 🌍 Traveller - Bangladesh Tourism App

A comprehensive Flutter mobile application for exploring tourist destinations across Bangladesh. This app helps users discover beautiful places, book hotels, plan tours, and manage their travel experiences.

## 📱 Features 

### User Features
- **Explore Destinations**: Browse tourist spots by division, district, and category
- **Place Details**: View detailed information, images, and reviews of tourist attractions
- **Hotel Booking**: Search and book hotels with real-time availability
- **Tour Planner**: AI-powered tour planning using OpenAI integration
- **Wishlist**: Save favorite destinations for future visits
- **Reviews & Ratings**: Read and write reviews for places and hotels
- **User Profile**: Manage personal information and booking history
- **Contact Support**: Direct communication with admin for queries
- **Q&A System**: Ask questions and get answers about destinations

### Admin Features
- **Admin Dashboard**: Manage bookings, contacts, and user queries
- **Hotel Management**: Add and manage hotel listings
- **Support Tickets**: Handle user support requests
- **Contact Management**: View and respond to user messages

## 🛠️ Technologies Used

### Frontend
- **Flutter**: Cross-platform mobile app development
- **Dart**: Programming language
- **Firebase Authentication**: User authentication and management
- **Cloud Firestore**: Real-time database for storing user data, bookings, and reviews
- **Firebase Storage**: Image and media storage
- **Shared Preferences**: Local data persistence

### Backend
- **Firebase Functions**: Serverless cloud functions
- **Node.js**: Runtime environment for cloud functions
- **OpenAI API**: AI-powered tour planning and Q&A features
- **Express.js**: RESTful API handling

## 📂 Project Structure

```
traveller/
├── lib/
│   ├── data/              # Static data for hotels and tourist spots
│   ├── models/            # Data models (Booking, etc.)
│   ├── screens/           # UI screens
│   │   ├── home_screen.dart
│   │   ├── place_details_screen.dart
│   │   ├── hotel_listing_screen.dart
│   │   ├── booking_form_screen.dart
│   │   ├── tour_planner_screen.dart
│   │   ├── admin_*.dart   # Admin screens
│   │   └── ...
│   ├── services/          # Business logic services
│   │   ├── qa_service.dart
│   │   ├── tour_planner_service.dart
│   │   ├── contact_service.dart
│   │   └── theme_service.dart
│   └── utils/             # Utility functions
│       ├── wishlist_service.dart
│       ├── review_service.dart
│       └── local_bookings.dart
├── functions/             # Firebase Cloud Functions
│   ├── index.js
│   ├── tourPlanner.js
│   ├── qaHandler.js
│   └── verifyEmail.js
├── assets/                # Images and media files
├── android/               # Android platform files
├── ios/                   # iOS platform files
└── web/                   # Web platform files
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase account
- OpenAI API key (for AI features)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ug2102047/traveller_apps.git
   cd traveller_apps
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a new Firebase project
   - Add Android/iOS apps to Firebase
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in respective platform folders
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Configure Cloud Functions**
   ```bash
   cd functions
   npm install
   ```
   - Create `.runtimeconfig.json` with your OpenAI API key:
   ```json
   {
     "openai": {
       "key": "your-openai-api-key"
     }
   }
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔥 Firebase Setup

### Firestore Collections
- `users` - User profiles and authentication data
- `bookings` - Hotel and tour bookings
- `reviews` - User reviews and ratings
- `contacts` - Support messages and queries
- `wishlists` - User saved destinations
- `qaThreads` - Q&A conversations

### Firebase Functions
Deploy cloud functions:
```bash
cd functions
firebase deploy --only functions
```

## 🎨 Features in Detail

### 1. Destination Discovery
- Browse by 8 administrative divisions of Bangladesh
- Filter by 64 districts
- Category-wise exploration (Historical, Natural, Religious, etc.)

### 2. Hotel Booking System
- Real-time availability checking
- Room details and pricing
- User booking management
- Mock payment integration

### 3. AI Tour Planner
- Personalized itinerary generation
- Budget-based recommendations
- Duration and preference customization

### 4. Review System
- Star ratings (1-5)
- Text reviews with images
- Verified user reviews
- Average rating calculation

## 🔐 Authentication
- Email/Password authentication
- Email verification
- Role-based access (User/Admin)
- Secure session management

## 📱 Screenshots
*(Add screenshots of your app here)*

## 🤝 Contributing
This is an academic project for Software Development Course (CCE-314) at Patuakhali Science and Technology University.

## 👨‍💻 Developer
**Student ID**: ug2102047  
**Email**: ug2102047@cse.pstu.ac.bd  
**Institution**: Patuakhali Science and Technology University

## 📄 License
This project is developed as part of academic coursework.

## 🙏 Acknowledgments
- Firebase for backend services
- OpenAI for AI-powered features
- Flutter community for excellent documentation
- Course instructors and mentors

## 📞 Support
For any queries or support, please contact through the in-app support system or email at ug2102047@cse.pstu.ac.bd
