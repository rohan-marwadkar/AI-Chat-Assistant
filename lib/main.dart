import 'package:chat_app/view/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(   
      apiKey: "AIzaSyDLJxlWoVL6_NjbJ-pjWl89SlkcoWylGfs",
      appId: "1:894843696870:android:44a741c9764a82d04e2d27", 
      messagingSenderId: "894843696870", 
      projectId: "chatapp-4a4c1",
    )
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:SplashScreen()
    );
  }
}