import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _dayHourRate = TextEditingController();

  final TextEditingController _nightHourRate = TextEditingController();
  final TextEditingController _paymentIntervalDays = TextEditingController();
  final TextEditingController _pensionPercentage = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _registerUser() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _db.collection('workers').doc(userCredential.user?.uid).set({
        'name': _nameController.text,
        'position': _positionController.text,
        'countProbablyWorkDate': 0,
        'countWorkDate': 0,
        'currency': '£',
        'dayHourRate': int.parse(_dayHourRate.text),
        'nightHourRate': int.parse(_nightHourRate.text),
        'nextPaymentDate': '',
        'paymentIntervalDays': int.parse(_paymentIntervalDays.text),
        'pensionPercentage': int.parse(_pensionPercentage.text),
        'workDate': [{}],
      });
      await Navigator.of(context).pushNamedAndRemoveUntil(
        homeRoute,
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: Text('${e.message}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _dayHourRate,
                decoration: const InputDecoration(
                  labelText: 'Day Hour Rate',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _nightHourRate,
                decoration: const InputDecoration(
                  labelText: 'Night Hour Rate',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _paymentIntervalDays,
                decoration: const InputDecoration(
                  labelText: 'Payment Interval in days',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _pensionPercentage,
                decoration: const InputDecoration(
                  labelText: 'Pension Percentage',
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _registerUser,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
