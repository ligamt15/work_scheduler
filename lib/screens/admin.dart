import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_widget.dart';
import '/data/worker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _workerNameController = TextEditingController();
  final TextEditingController _workerPositionController =
      TextEditingController();
  final TextEditingController _workerCurrencyController =
      TextEditingController();
  final TextEditingController _workerHourRateController =
      TextEditingController();
  final TextEditingController _workerPensionPersentageController =
      TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<List<Worker>>? _workersFuture;
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _refreshWorkers();
  }

  void _refreshWorkers() {
    setState(() {
      _workersFuture = fetchWorkerFromDatabase();
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return BaseWidget(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Modify Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await currentUser?.updatePassword(_passwordController.text);
                  await currentUser?.reauthenticateWithCredential(
                    EmailAuthProvider.credential(
                      email: currentUser!.email!,
                      password: _passwordController.text,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully.'),
                    ),
                  );
                  _passwordController.clear();
                } on FirebaseAuthException catch (e) {
                  print(e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? ''),
                    ),
                  );
                }
              },
              child: const Text('Modify Password'),
            ),
            FutureBuilder<List<Worker>>(
              future: _workersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Show loading spinner while waiting for data
                } else if (snapshot.hasError) {
                  return Text(
                      'Error: ${snapshot.error}'); // Show error message if something went wrong
                } else {
                  _workers = snapshot.data!;
                  return Column(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Modify Worker',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _workerNameController,
                        decoration: InputDecoration(
                          labelText: 'Current name: ${_workers[0].name}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _workerPositionController,
                        decoration: InputDecoration(
                          labelText:
                              'Current position: ${_workers[0].position}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _workerCurrencyController,
                        decoration: InputDecoration(
                          labelText:
                              'Current currency: ${_workers[0].currency}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _workerHourRateController,
                        decoration: InputDecoration(
                          labelText:
                              'Current hour rate: ${_workers[0].hourRate}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _workerPensionPersentageController,
                        decoration: InputDecoration(
                          labelText:
                              'Current pension persentage: ${_workers[0].pensionPercentage}%',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final updatedWorker = Worker(
                              name: _workerNameController.text.isNotEmpty
                                  ? _workerNameController.text
                                  : _workers[0].name,
                              position:
                                  _workerPositionController.text.isNotEmpty
                                      ? _workerPositionController.text
                                      : _workers[0].position,
                              currency:
                                  _workerCurrencyController.text.isNotEmpty
                                      ? _workerCurrencyController.text
                                      : _workers[0].currency,
                              hourRate: _workerHourRateController
                                      .text.isNotEmpty
                                  ? double.parse(_workerHourRateController.text)
                                  : _workers[0].hourRate,
                              pensionPercentage:
                                  _workerPensionPersentageController
                                          .text.isNotEmpty
                                      ? int.parse(
                                          _workerPensionPersentageController
                                              .text)
                                      : _workers[0].pensionPercentage,
                              workDate: _workers[0].workDate,
                            );
                            await FirebaseFirestore.instance
                                .collection('workers')
                                .doc(currentUser?.uid)
                                .update(updatedWorker.toMap());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Worker updated successfully.'),
                              ),
                            );
                            _workerNameController.clear();
                            _workerPositionController.clear();
                            _workerCurrencyController.clear();
                            _workerHourRateController.clear();
                            _workerPensionPersentageController.clear();
                            _refreshWorkers();
                          } catch (e) {
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update worker.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Modify Worker'),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
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
        // Создаем экземпляр Worker из данных снимка
        final worker = Worker.fromMap(data);

        // Добавляем созданный экземпляр Worker в список workers
        List<Worker> workers = [worker];

        // Возвращаем список workers
        return workers;
      } else {
        print('Документ не найден');
        return [];
      }
    } catch (error) {
      // Обработка ошибок
      if (currentUser == null) {
        print('User is not logged in');
      } else {
        print('Error fetching worker: $error');
      }

      return [];
    }
  }
}
