import 'package:flutter/material.dart';
import '../payslip_calculations.dart';
import 'base_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/data/worker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    List<Worker> _workers = [];
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          loginPage,
          (Route<dynamic> route) => false,
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Hi ${currentUser.email}! You logged in successfully.'),
          ),
        );
      });

      @override
      HomePage createState() => HomePage();
    }

    return BaseWidget(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: FutureBuilder(
        future: fetchWorkerFromDatabase(),
        builder: (BuildContext context, AsyncSnapshot<List<Worker>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // Check if the list of workers is empty
            if (snapshot.data?.isEmpty ?? true) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Center(
                    child:
                        Text('No workers found. Please register a new worker.'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to the registration page
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        registrationPage,
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text(
                        'Register Worker TODO: Implement registration page navigation'),
                  ),
                ],
              );
            } else {
              _workers = snapshot.data!;
              return Column(
                children: [
                  const SizedBox(height: 150),
                  Container(
                    height: 50,
                    child: ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return Column(children: [
                          Text(
                              'Hello ${_workers[0].name} the ${_workers[0].position}!'),
                        ]);
                      },
                    ),
                  ),
                  FutureBuilder<List<dynamic>>(
                    future: getSalaries(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        print('Error: ${snapshot.error}');
                        return const Text(
                            'Cant calculate your salary. Check your calendar and next payment date');
                      } else {
                        return Text(
                            'Salary is: ${snapshot.data?[0]}, Count of working days: ${snapshot.data?[1]}${snapshot.data?[6]}\nProbably salary is: ${snapshot.data?[2]}${snapshot.data?[6]}, Count of all days: ${snapshot.data?[3]}\nTax amount: ${snapshot.data?[4]}\nAnnual salary is: ${snapshot.data?[5]}${snapshot.data?[6]}');
                      }
                    },
                  )
                ],
              );
            }
          }
        },
      ),
    );
  }
}

Future<List<Worker>> fetchWorkerFromDatabase() async {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('workers')
        .doc(currentUser?.uid)
        .get();

    final Map<String, dynamic>? data = snapshot.data();
    if (data != null) {
      final worker = Worker.fromMap(data);

      List<Worker> workers = [worker];

      return workers;
    } else {
      print('Doc not found in database');
      return [];
    }
  } catch (error) {
    if (currentUser == null) {
      print('User is not logged in');
    } else {
      print('Error fetching worker: $error');
    }
    return [];
  }
}

Future<List<dynamic>>? getSalaries() async {
  List<dynamic> salaries = await updateWorkDays();

  return salaries;
}
