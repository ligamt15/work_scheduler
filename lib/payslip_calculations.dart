import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

final User? currentUser = FirebaseAuth.instance.currentUser;
int workingDaysCount = 0;
int probablyWorkingDaysCount = 0;
updateWorkDays() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Get a reference to the Firestore database
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Get all workdays of the current user
  final snapshot = await FirebaseFirestore.instance
      .collection('workers')
      .doc(currentUser?.uid)
      .get();

  final dayHourRate = snapshot.data()?['dayHourRate'];
  final nightHourRate = snapshot.data()?['nightHourRate'];
  final workDate = snapshot.data()?['workDate'];
  final workingDays =
      workDate.where((day) => day['Event'] == 'Working Day').toList();

  final probablyWorkingDays = workDate
      .where((day) => day['Event'] == 'Could be a Working Day')
      .toList();

  final pensionPersentage = snapshot.data()?['pensionPercentage'];

  final getPayday = DateTime.parse(snapshot.data()?['nextPaymentDate']);
  final payday = getPayday.subtract(Duration(days: 4));
  final startDate = payday.subtract(Duration(days: 28));

  List<DateTime> generateDateRange(DateTime startDate, DateTime endDate) {
    List<DateTime> range = [];
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      range.add(startDate.add(Duration(days: i)));
    }
    return range;
  }

  final dateRange = generateDateRange(startDate, payday);

  final parsedWorkDates = workingDays.map((item) {
    return DateTime(item['Year'], item['Month'], item['Day']);
  }).toList();

  final parsedProbablyWorkDates = probablyWorkingDays.map((item) {
    return DateTime(item['Year'], item['Month'], item['Day']);
  }).toList();

  final filteredWorkDates = parsedWorkDates.where((item) {
    return dateRange.contains(item);
  }).toList();

  final filteredProbablyWorkDates = parsedProbablyWorkDates.where((item) {
    return dateRange.contains(item);
  }).toList();

  final salary = (filteredWorkDates.length * 5 * nightHourRate) +
      (filteredWorkDates.length * 3 * dayHourRate);

  final salaryAfterPension = (salary * pensionPersentage / 100);

  final probablySalary = salary +
      (filteredProbablyWorkDates.length * 5 * nightHourRate) +
      (filteredProbablyWorkDates.length * 3 * dayHourRate);
  final probablySalaryAfterPension = (probablySalary * pensionPersentage / 100);

  return [salaryAfterPension, probablySalaryAfterPension];
}
