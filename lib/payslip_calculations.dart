import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final User? currentUser = FirebaseAuth.instance.currentUser;

Future<List<dynamic>> updateWorkDays() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  var taxStatus = ' without tax';
  double monthlyTaxAmount = 0;
  double probablySalaryAfterTax = 0;
  double probablySalaryBeforeTax = 0;
  double taxFreeAllowance = 12570;
  double taxRate = 0.20;
  double monthlyNIC = 0;
  double lowerLimitNI =
      242; // 242 * 4.33 (approximate conversion from weekly to monthly)
  double upperLimitNI =
      967; // 967 * 4.33 (approximate conversion from weekly to monthly)
  double lowerRateNI = 0.08;
  double upperRateNI = 0.02;

  // Get a reference to the Firestore database
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Get all workdays of the current user
  final snapshot = await db.collection('workers').doc(currentUser?.uid).get();

  final dayHourRate = snapshot.data()?['dayHourRate'];
  final nightHourRate = snapshot.data()?['nightHourRate'];

  final workDate = snapshot.data()?['workDate'];

  final workingDays =
      workDate.where((day) => day['Event'] == 'Working Day').toList();
  final probablyWorkingDays = workDate
      .where((day) => day['Event'] == 'Could be a Working Day')
      .toList();

  final pensionPercentage = snapshot.data()?['pensionPercentage'];

  final getPayday = DateTime.parse(snapshot.data()?['nextPaymentDate']);
  final payday = getPayday.subtract(const Duration(days: 4));
  final startDate = payday.subtract(const Duration(days: 28));

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

  // Calculate monthly salary and probable salary
  final salary = (filteredWorkDates.length * 4.5 * nightHourRate) +
      (filteredWorkDates.length * 3 * dayHourRate);
  var salaryAfterPension = salary - (salary * pensionPercentage / 100);

  final probablySalary =
      (filteredProbablyWorkDates.length * 4.5 * nightHourRate) +
          (filteredProbablyWorkDates.length * 3 * dayHourRate);

  var probablySalaryAfterPension =
      probablySalary - (probablySalary * pensionPercentage / 100);
  probablySalaryAfterPension += salaryAfterPension;

  probablySalaryBeforeTax = probablySalaryAfterPension;

  // Annual salary calculations for tax purposes
  final annualProbablySalary = probablySalaryAfterPension * 13; // 13 periods

  var earningsBtwLoAndUp = (probablySalaryAfterPension / 4) - lowerLimitNI;
  if ((probablySalaryAfterPension / 4) > upperLimitNI) {
    var earningsAboveUp = upperLimitNI - (probablySalaryAfterPension / 4);
    monthlyNIC =
        earningsBtwLoAndUp * lowerRateNI + earningsAboveUp * upperRateNI;
  } else {
    monthlyNIC = earningsBtwLoAndUp * lowerRateNI * 4;
  }

  probablySalaryAfterPension -= monthlyNIC;

  // Monthly (4-week) tax calculations
  if (annualProbablySalary > taxFreeAllowance) {
    double excessIncome = annualProbablySalary - taxFreeAllowance;
    double annualTax = excessIncome * taxRate;
    double monthlyProbablyTaxAmount = annualTax / 13;
    probablySalaryAfterTax =
        probablySalaryAfterPension - monthlyProbablyTaxAmount;
    monthlyTaxAmount = monthlyProbablyTaxAmount;
    taxStatus = ' after tax';
  } else {
    monthlyTaxAmount = 0; // No tax if within the allowance
    probablySalaryAfterTax = probablySalaryAfterPension;
  }

  return [
    salaryAfterPension.round(),
    filteredWorkDates.length,
    probablySalaryAfterTax.round(),
    probablySalaryBeforeTax.round(),
    (filteredProbablyWorkDates.length + filteredWorkDates.length),
    monthlyTaxAmount.round(),
    monthlyNIC.round(),
    taxStatus
  ];
}
