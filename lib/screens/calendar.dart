import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:work_scheduler_v0/screens/base_widget.dart';

int crossAxisCount = 0;
double childAspectRatio = 0;

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
const Color workDayColor = Color.fromARGB(195, 158, 214, 105);
const Color probablyWorkingColor = Color.fromARGB(195, 239, 114, 158);
const Color payDayColor = Color.fromARGB(255, 127, 125, 218);
const Color currentDayColor = Color.fromARGB(255, 70, 62, 62);
final User? currentUser = FirebaseAuth.instance.currentUser;

int currentMonth = DateTime.now().month;

List<Map<String, dynamic>> filterAndSortWorkDates(
    List<Map<String, dynamic>> workDates, int currentMonth) {
  List<Map<String, dynamic>> sortedWorkDates = List.from(workDates);

  sortedWorkDates = sortedWorkDates.where((item) {
    return item['Month'] == currentMonth;
  }).toList();

  sortedWorkDates.sort((a, b) {
    return DateTime.parse(
            '${a['Year']}-${a['Month'].toString().padLeft(2, '0')}-${a['Day'].toString().padLeft(2, '0')}')
        .compareTo(
      DateTime.parse(
          '${b['Year']}-${b['Month'].toString().padLeft(2, '0')}-${b['Day'].toString().padLeft(2, '0')}'),
    );
  });

  return sortedWorkDates;
}

class Event {
  final int day;
  final int month;
  final int year;
  final String type;

  Event({
    required this.day,
    required this.month,
    required this.year,
    required this.type,
  });

  @override
  String toString() {
    return 'Event on ${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}: $type';
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime today = DateTime.now();
  Event? _selectedEvent;

  @override
  void initState() {
    super.initState();
    fetchUserDocument().then((doc) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('workers')
              .doc(_auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            // Your code here

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final screenWidth = MediaQuery.of(context).size.width;

            if (screenWidth < 450) {
              // Small screen (like a phone)
              crossAxisCount = 2;
              childAspectRatio = 2;
            } else if (screenWidth < 600) {
              // Small screen (like a phone)
              crossAxisCount = 2;
              childAspectRatio = 3;
            } else if (screenWidth < 900) {
              // Medium screen (like a tablet)
              crossAxisCount = 3;
              childAspectRatio = 3;
            } else {
              // Large screen (like a desktop)
              crossAxisCount = 5;
              childAspectRatio = 2;
            }

            DateTime nextPaymentDate =
                DateTime.parse(snapshot.data!['nextPaymentDate']);
            DateTime nextPaymentDateBefore = nextPaymentDate
                .subtract(Duration(days: nextPaymentDate.day * 2));
            DateTime nextPaymentDateAfter =
                nextPaymentDate.add(Duration(days: nextPaymentDate.day * 2));
            List<Map<String, dynamic>> workDates =
                List<Map<String, dynamic>>.from(snapshot.data!['workDate']);

            List<Event> events = workDates.map((date) {
              return Event(
                day: date['Day'],
                month: date['Month'],
                year: date['Year'],
                type: date['Event'], // can be null
              );
            }).toList();

            List<Map<String, dynamic>> sortedWorkDates =
                filterAndSortWorkDates(workDates, currentMonth);

            Map<String, List<Event>> eventMap = {};
            for (var event in events) {
              final eventDate = DateTime(
                event.year,
                event.month,
                event.day,
              );
              final dateKey = formatDate(eventDate);
              eventMap[dateKey] = eventMap[dateKey] ?? [];
              eventMap[dateKey]!.add(event);
            }

            return ListView(children: <Widget>[
              TableCalendar(
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.blue[800]),
                  weekdayStyle: TextStyle(color: Colors.teal[800]),
                ),
                firstDay: nextPaymentDateBefore,
                lastDay: nextPaymentDateAfter,
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  setState(() {
                    currentMonth = focusedDay.month;
                    sortedWorkDates =
                        filterAndSortWorkDates(workDates, currentMonth);
                  });
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(
                    () {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Event'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    if (eventMap[formatDate(selectedDay)] ==
                                        null) {
                                      setState(() {
                                        _storeEventInFirestore(
                                            selectedDay, 'Working Day');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${formatDate(selectedDay)} Marked as Working Day'),
                                            duration:
                                                const Duration(seconds: 1),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${formatDate(selectedDay)} Already a ${eventMap[formatDate(selectedDay)]![0].type}'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _selectedDay = null;
                                    });
                                  },
                                  child: const Text('Working Day'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (eventMap[formatDate(selectedDay)] ==
                                        null) {
                                      setState(() {
                                        _storeEventInFirestore(selectedDay,
                                            'Could be a Working Day');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${formatDate(selectedDay)} Could be a Working Day'),
                                            duration:
                                                const Duration(seconds: 1),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${formatDate(selectedDay)} Already a ${eventMap[formatDate(selectedDay)]![0].type}'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _selectedDay = null;
                                    });
                                  },
                                  child: const Text('Could be a Working Day'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _storeEventInFirestore(
                                          selectedDay, 'Clear Events');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${formatDate(selectedDay)} Day Cleared'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    });
                                    setState(() {
                                      _selectedDay = null;
                                    });
                                  },
                                  child: const Text('Clear Events'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      snapshot.data!.reference.update({
                                        'nextPaymentDate':
                                            formatDate(selectedDay)
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Next payment day is ${formatDate(selectedDay)}'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    });
                                    setState(() {
                                      _selectedDay = null;
                                    });
                                  },
                                  child: const Text('Mark as Payment Day'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                eventLoader: (day) {
                  final dateKey = formatDate(day);
                  return eventMap[dateKey] ?? [];
                },
                calendarStyle: CalendarStyle(
                  outsideDecoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _markerColorSelected(_selectedEvent),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: true,
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _markerColorSelected(_selectedEvent),
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: _buildEventsMarker(date, events),
                      );
                    }

                    return Container();
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    final dateKey = formatDate(day);

                    if (formatDate(day) == snapshot.data!['nextPaymentDate']) {
                      return Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: eventMap[dateKey]?[0] != null
                                ? _markerColor(eventMap[dateKey]![0])
                                : const Color.fromARGB(255, 224, 224, 224),
                            border: const Border.symmetric(
                              horizontal: BorderSide(
                                color: payDayColor,
                                width: 8,
                              ),
                            )),
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    if (eventMap[dateKey] != null) {
                      return Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _markerColor(eventMap[dateKey]![0]),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12.0,
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 224, 224, 224),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12.0,
                          ),
                        ),
                      );
                    }
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final dateKey = formatDate(day);
                    if (eventMap[dateKey] != null) {
                      return Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _markerColor(eventMap[dateKey]![0]),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12.0,
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        alignment: Alignment.center,
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 224, 224, 224),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: currentDayColor,
                                width: 8,
                              ),
                            )),
                        child: Text('${day.day}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            )),
                      );
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: workDayColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('Work Day'),
                      ],
                    ),
                    const SizedBox(width: 5),
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: probablyWorkingColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('Could be a Working Day'),
                      ],
                    ),
                    const SizedBox(width: 5),
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 224, 224, 224),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: payDayColor,
                                width: 5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width:
                                5), // Add some space between the circle and the text
                        const Text('Pay Day'),
                      ],
                    ),
                    const SizedBox(width: 5),
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 224, 224, 224),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: currentDayColor,
                                width: 5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width:
                                5), // Add some space between the circle and the text
                        const Text('Current Day'),
                      ],
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
              Center(
                child: Text(
                  'Events for the month of ${DateFormat.MMMM().format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(children: [
                SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 30, right: 30, top: 25),
                    child: Column(
                      children: [
                        GridView.count(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ...eventsOfMonth(sortedWorkDates, currentMonth)
                                .map((event) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    textAlign: TextAlign.left,
                                    '${event['Month']}-${event['Day']}-${event['Year']} ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${event['Event']}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            })
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ]);
          }),
    );
  }

  List<Map<String, dynamic>> eventsOfMonth(
      List<Map<String, dynamic>> sortedWorkDates, int month) {
    return sortedWorkDates.where((item) {
      return item['Month'] == month;
    }).toList();
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return Container(
      alignment: Alignment.topLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _markerColor(events[0]), // Use the first event for color
        ),
      ),
    );
  }

  Color _markerColor(Event event) {
    switch (event.type) {
      case 'Working Day':
        return workDayColor;
      case 'Could be a Working Day':
        return probablyWorkingColor;
      default:
        return const Color.fromARGB(255, 224, 224, 224);
    }
  }

  Color _markerColorSelected(Event? event) {
    switch (event?.type) {
      case 'Working Day':
        return workDayColor;
      case 'Could be a Working Day':
        return probablyWorkingColor;
      default:
        return const Color.fromARGB(255, 224, 224, 224);
    }
  }

  Future<DocumentSnapshot> fetchUserDocument() async {
    return await _firestore
        .collection('workers')
        .doc(_auth.currentUser?.uid)
        .get();
  }

  Future<void> _storeEventInFirestore(DateTime date, String event) async {
    DocumentSnapshot docSnapshot = await fetchUserDocument();
    List workDate = docSnapshot['workDate'];

    try {
      if (event == 'Clear Events') {
        workDate = workDate.where((item) {
          return !(item['Year'] == date.year &&
              item['Month'] == date.month &&
              item['Day'] == date.day);
        }).toList();

        await docSnapshot.reference.update({'workDate': workDate});
      } else {
        await docSnapshot.reference.update({
          'workDate': FieldValue.arrayUnion([
            {
              'Year': date.year,
              'Month': date.month,
              'Day': date.day,
              'Event': event
            }
          ])
        });
      }
    } catch (e) {
      print('Failed to add event: $e');
    }
  }
}
