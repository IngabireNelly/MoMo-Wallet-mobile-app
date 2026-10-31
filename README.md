# MoMo Wallet

MoMo Wallet is a Flutter wallet app where users sign in with Firebase Authentication and manage Rwandan franc (RWF) transactions stored in Cloud Firestore under their own user ID, with wallet updates shown live.

## Features

- Create an account or log in with email and password.
- View your balance, total money in, total money out, and lowest balance.
- Record send money and cash out transactions, with balance and amount checks.
- Filter transactions by all, incoming, or outgoing, and delete a transaction with an undo option.
- Store transactions in `users/{uid}/transactions` and display Firestore updates as they arrive.

Firestore access is scoped in the app to the signed-in user's UID. To enforce that users cannot read or change another user's data, configure Firestore Security Rules to allow access only when the authenticated UID matches the document UID.

## Screenshots

Add the screenshots to the `screenshots/` folder at these paths:

![Login](screenshots/login.png)

![My data in Firestore](screenshots/console.png)

![Live update](screenshots/live.png)

![Second account sees only its own data](screenshots/denied.png)

## Firebase setup

This app uses Firebase Authentication and Cloud Firestore. Configure a Firebase project for the Android app, enable Email/Password sign-in, create the Firestore database, and add the downloaded `google-services.json` file to `android/app/` before running the app.

## Run the app

```sh
flutter pub get
flutter run
```
